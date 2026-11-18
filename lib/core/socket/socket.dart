import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_endpoints.dart';
import '../storage/auth_local_storage.dart';

/// Manages the Socket.IO connection lifecycle.
///
/// Features:
/// - Singleton pattern — one socket for the entire app session.
/// - Connects with JWT auth token from [AuthLocalStorage].
/// - Configurable automatic reconnection with exponential back-off capped at 5s.
/// - Wildcard listener ([onAny]) to log and process EVERY incoming server event.
/// - Full logging whenever events are RAISED (emitted) or RECEIVED.
/// - Automatically joins driver & user rooms on connect/reconnect.
/// - Broadcasts connection status via [onConnected] stream.
/// - Broadcasts booking creation events via [onBookingCreated] stream.
/// - Safe [disconnectFully] tears down the socket and all handlers cleanly.
class SocketService {
  // ──────────────────────────────────────────────
  //  Singleton
  // ──────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  SocketService._internal();
  factory SocketService() => _instance;

  // ──────────────────────────────────────────────
  //  Socket Event Constants
  // ──────────────────────────────────────────────
  /// Standard booking creation event names
  static const String eventBookingCreated = 'BOOKING_CREATED';
  static const String eventBookingCreatedLower = 'booking_created';
  static const String eventBookingCreatedColon = 'booking:created';
  static const String eventBookingRequest = 'BOOKING_REQUEST';
  static const String eventBookingRequestLower = 'booking_request';
  static const String eventNewBooking = 'new_booking';
  static const String eventRideNewAvailable = 'ride:new_available';
  static const String eventRideBooked = 'ride_booked';
  static const String eventSlotBooked = 'slot_booked';

  // ──────────────────────────────────────────────
  //  Internal state
  // ──────────────────────────────────────────────
  io.Socket? _socket;
  final AuthLocalStorage _storageService = AuthLocalStorage();

  // ──────────────────────────────────────────────
  //  Public streams
  // ──────────────────────────────────────────────

  /// Fires every time the socket successfully connects or reconnects.
  final _connectedController = StreamController<void>.broadcast();
  Stream<void> get onConnected => _connectedController.stream;

  /// Fires every time the socket disconnects (any reason).
  final _disconnectedController = StreamController<String>.broadcast();
  Stream<String> get onDisconnected => _disconnectedController.stream;

  /// Fires every time a booking event is received from the server.
  final _bookingCreatedController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onBookingCreated => _bookingCreatedController.stream;

  /// Fires every time any socket event is received from the server.
  final _anyEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onAnyEvent => _anyEventController.stream;

  // ──────────────────────────────────────────────
  //  Accessors
  // ──────────────────────────────────────────────

  /// The underlying socket instance (null if never connected).
  io.Socket? get socket => _socket;

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  // ──────────────────────────────────────────────
  //  Public API: 1. Connect
  // ──────────────────────────────────────────────

  /// Connects the socket using the stored user auth token.
  ///
  /// Reads the token from [AuthLocalStorage]. If no token is found,
  /// connection is attempted with an empty token (or guest access).
  ///
  /// Calling [connect] while already connected is safe — preserves existing session.
  Future<void> connect() async {
    final token = await _storageService.getAccessTokenAsync() ??
        _storageService.getToken() ??
        '';

    if (token.isEmpty) {
      _printLog('⚠️ [SocketService] No token found in storage — attempting connection.');
    }

    _connectWithToken(token);
  }

  /// Connects using an explicit [token] (e.g. right after verification/login).
  void connectWithToken(String token) {
    if (token.isEmpty) {
      _printLog('⚠️ [SocketService] Empty token provided — attempting connection.');
    }
    _connectWithToken(token);
  }

  /// Ensures the socket is connected, trying to reconnect once if not.
  ///
  /// Returns `true` if connected within ~3 s, `false` otherwise.
  Future<bool> ensureConnected() async {
    if (isConnected) return true;
    await connect();
    // Wait up to 3 s for the connection to be established.
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (isConnected) return true;
    }
    return false;
  }

  // ──────────────────────────────────────────────
  //  Public API: 2. Emit & Raise Events
  // ──────────────────────────────────────────────

  /// Formats any payload into pretty-printed multi-line JSON or formatted text.
  String _formatData(dynamic data) {
    if (data == null) return '   (null)';
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('     ').convert(data);
      }
      final decoded = jsonDecode(data.toString());
      return const JsonEncoder.withIndent('     ').convert(decoded);
    } catch (_) {
      return '     $data';
    }
  }

  /// Emits an event on the socket with full debug printing (no-op if not connected).
  void emit(String event, dynamic data) {
    if (!isConnected) {
      _printLog('⚠️ [SocketService] emit("$event") skipped — socket is not connected.');
      return;
    }

    final profile = _storageService.getUserProfile();
    final driverName = profile?.fullName ?? _storageService.getFullName() ?? 'Driver';
    final driverPhone = profile?.phoneNumber ?? '+91 9876543210';
    final formattedPayload = _formatData(data);

    final sb = StringBuffer();
    sb.writeln('\n══════════════════════════════════════════════════════════════════════════');
    sb.writeln('🚀 [SOCKET EVENT RAISED / EMITTED BY CLIENT]');
    sb.writeln('──────────────────────────────────────────────────────────────────────────');
    sb.writeln('   • EVENT NAME    : "$event"');
    sb.writeln('   • SOCKET ID     : ${_socket?.id ?? "unknown"}');
    sb.writeln('   • SERVER URL    : ${ApiEndpoints.socketUrl}');
    sb.writeln('   • DRIVER NAME   : $driverName');
    sb.writeln('   • DRIVER PHONE  : $driverPhone');
    sb.writeln('   • TIMESTAMP     : ${DateTime.now().toIso8601String()}');
    sb.writeln('──────────────────────────────────────────────────────────────────────────');
    sb.writeln('   • FULL DATA PAYLOAD:');
    sb.writeln(formattedPayload);
    sb.writeln('══════════════════════════════════════════════════════════════════════════\n');

    _printLog(sb.toString());
    _socket!.emit(event, data);
  }

  /// Dedicated emit helper for booking creation.
  ///
  /// Sends the booking data payload to the backend under multiple standard event keys.
  void emitBookingCreated(dynamic data) {
    _printLog('📢 [SocketService] Raising booking created event across standard socket keys...');
    emit(eventBookingCreated, data);
    emit(eventBookingCreatedLower, data);
    emit(eventNewBooking, data);
    emit(eventRideNewAvailable, data);
  }

  /// Joins the driver and user rooms so backend broadcasts directed to driverId or userId are received.
  void joinDriverRooms([String? explicitDriverId]) {
    try {
      String? driverId = explicitDriverId;
      if (driverId == null || driverId.isEmpty) {
        final profile = _storageService.getUserProfile();
        driverId = profile?.id;
      }
      if (driverId == null || driverId.isEmpty) {
        final userData = _storageService.getUserData();
        driverId = userData?['id']?.toString() ?? userData?['_id']?.toString();
      }

      // If still empty, attempt to extract 'id' from stored JWT token payload
      if (driverId == null || driverId.isEmpty) {
        final token = _storageService.getToken() ?? '';
        if (token.contains('.')) {
          final parts = token.split('.');
          if (parts.length >= 2) {
            final normalized = base64Url.normalize(parts[1]);
            final decodedStr = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(decodedStr);
            if (payload is Map && payload['id'] != null) {
              driverId = payload['id'].toString();
            }
          }
        }
      }

      if (driverId != null && driverId.isNotEmpty) {
        _printLog('🚪 [SocketService] Joining driver/user room for ID: $driverId');
        emit('join', {'userId': driverId, 'driverId': driverId, 'role': 'driver'});
        emit('join_driver', driverId);
        emit('driver:join', driverId);
        emit('join_user', driverId);
        emit('join', driverId);
        emit('driver:online', {'userId': driverId, 'driverId': driverId, 'isOnline': true});
        emit('driver_online', {'userId': driverId, 'driverId': driverId, 'isOnline': true});
      }
    } catch (e) {
      _printLog('⚠️ [SocketService] Error while joining driver rooms: $e');
    }
  }

  /// Joins a specific ride's room so booking events targeted to that ride are received.
  void joinRideRoom(String rideId) {
    if (rideId.isEmpty) return;
    _printLog('🚪 [SocketService] Joining ride room for Ride ID: $rideId');
    emit('join', {'rideId': rideId});
    emit('joinRide', rideId);
    emit('join_ride', rideId);
    emit('join', 'ride_$rideId');
  }

  // ──────────────────────────────────────────────
  //  Event Subscriptions
  // ──────────────────────────────────────────────

  /// Subscribes [handler] to a named socket event.
  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);

  /// Subscribes a handler to all incoming socket events.
  void onAny(void Function(String event, dynamic data) handler) {
    _socket?.onAny((event, data) => handler(event.toString(), data));
  }

  /// Removes a specific [handler] (or all handlers) for a named socket event.
  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  /// Disables listening to any incoming event.
  void offAny([void Function(String event, dynamic data)? handler]) {
    _socket?.offAny();
  }

  /// Disconnects the socket cleanly, frees all resources, and sets the
  /// internal reference to `null`.
  void disconnectFully() {
    if (_socket != null) {
      _printLog('🔌 [SocketService] Disconnecting socket fully.');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  /// Closes all broadcast stream controllers. Call only when the service
  /// itself is being destroyed (e.g. during app shutdown).
  void dispose() {
    disconnectFully();
    _connectedController.close();
    _disconnectedController.close();
    _bookingCreatedController.close();
    _anyEventController.close();
  }

  // ──────────────────────────────────────────────
  //  Internal helpers
  // ──────────────────────────────────────────────

  void _connectWithToken(String token) {
    try {
      // If already connected, preserve existing socket connection
      if (_socket != null && _socket!.connected) {
        _printLog('⚡ [SocketService] Socket already connected (id: ${_socket?.id}) — preserving session.');
        joinDriverRooms();
        return;
      }

      // Tear down any existing inactive socket before creating a new one.
      if (_socket != null) {
        _printLog('🔄 [SocketService] Re-connecting with updated token.');
        disconnectFully();
      }

      _printLog('🔌 [SocketService] Initiating socket connection to ${ApiEndpoints.socketUrl}…');

      final optionBuilder = io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000) // first retry after 1 s
          .setReconnectionDelayMax(5000) // cap at 5 s
          .setReconnectionAttempts(999999) // retry indefinitely
          .enableAutoConnect();

      if (token.isNotEmpty) {
        optionBuilder
            .setAuth({'token': token})
            .setQuery({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'});
      }

      _socket = io.io(
        ApiEndpoints.socketUrl,
        optionBuilder.build(),
      );

      _registerBaseListeners(token);
      _socket!.connect();
    } catch (e, stack) {
      _printLog('❌ [SocketService] Error initiating socket connection: $e\n$stack');
    }
  }

  void _registerBaseListeners(String token) {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      final profile = _storageService.getUserProfile();
      final driverId = profile?.id ??
          _storageService.getUserData()?['id']?.toString() ??
          _storageService.getUserData()?['_id']?.toString() ??
          'N/A';
      final driverName =
          profile?.fullName ?? _storageService.getFullName() ?? 'Driver';
      final driverPhone = profile?.phoneNumber ?? '';

      final sb = StringBuffer();
      sb.writeln('\n══════════════════════════════════════════════════════════════════════════');
      sb.writeln('✅ [SOCKET SERVICE: CONNECTED SUCCESSFULLY]');
      sb.writeln('──────────────────────────────────────────────────────────────────────────');
      sb.writeln('   • SOCKET ID    : ${_socket?.id}');
      sb.writeln('   • SERVER URL   : ${ApiEndpoints.socketUrl}');
      sb.writeln('   • DRIVER ID    : $driverId');
      sb.writeln('   • DRIVER NAME  : $driverName');
      if (driverPhone.isNotEmpty) sb.writeln('   • DRIVER PHONE : $driverPhone');
      sb.writeln('   • CONNECT TIME : ${DateTime.now().toIso8601String()}');
      sb.writeln('══════════════════════════════════════════════════════════════════════════\n');

      _printLog(sb.toString());
      _connectedController.add(null);
      // Automatically register driver and join user/driver rooms upon connection
      joinDriverRooms();
    });

    // ──────────────────────────────────────────────
    // 1. Wildcard listener: Log EVERY event from server
    // ──────────────────────────────────────────────
    _socket!.onAny((event, data) {
      final eventName = event.toString();
      final formattedPayload = _formatData(data);

      final sb = StringBuffer();
      sb.writeln('\n══════════════════════════════════════════════════════════════════════════');
      sb.writeln('📩 [SOCKET EVENT RECEIVED FROM SERVER]');
      sb.writeln('──────────────────────────────────────────────────────────────────────────');
      sb.writeln('   • EVENT NAME    : "$eventName"');
      sb.writeln('   • SOCKET ID     : ${_socket?.id ?? "unknown"}');
      sb.writeln('   • SERVER URL    : ${ApiEndpoints.socketUrl}');
      sb.writeln('   • TIMESTAMP     : ${DateTime.now().toIso8601String()}');
      sb.writeln('──────────────────────────────────────────────────────────────────────────');
      sb.writeln('   • FULL PAYLOAD RECEIVED:');
      sb.writeln(formattedPayload);
      sb.writeln('══════════════════════════════════════════════════════════════════════════\n');

      _printLog(sb.toString());

      _anyEventController.add({'event': eventName, 'data': data});

      // Forward to booking controller if event is a driver booking request
      // (Exclude BOOKING_CONFIRMED which is passenger-facing confirmation)
      final upper = eventName.toUpperCase();
      final isDriverBookingRequest = upper == 'BOOKING_CREATED' ||
          upper == 'BOOKING_REQUEST' ||
          upper == 'NEW_BOOKING' ||
          upper == 'RIDE:NEW_AVAILABLE' ||
          upper == 'SLOT_BOOKED' ||
          upper == 'RIDE_BOOKED' ||
          (upper.contains('BOOKING') &&
              !upper.contains('CONFIRM') &&
              !upper.contains('CANCEL') &&
              !upper.contains('USER') &&
              !upper.contains('PASSENGER'));

      if (isDriverBookingRequest) {
        _bookingCreatedController.add(data);
      }
    });

    // ──────────────────────────────────────────────
    // 2. Explicit booking event listeners (fallback for specific keys)
    // ──────────────────────────────────────────────
    _socket!.onDisconnect((reason) {
      final msg = reason?.toString() ?? 'unknown';
      _printLog('❌ [SocketService] Disconnected — reason: $msg');
      _disconnectedController.add(msg);
    });

    _socket!.onConnectError((error) {
      _printLog('❗ [SocketService] Connection error: $error');
    });

    _socket!.onReconnect((attempt) {
      _printLog('🔄 [SocketService] Reconnected after attempt $attempt (Socket ID: ${_socket?.id})');
      _connectedController.add(null);
    });

    _socket!.onReconnectAttempt((attempt) {
      _printLog('🔁 [SocketService] Reconnect attempt #$attempt…');
    });

    _socket!.onReconnectError((error) {
      _printLog('❗ [SocketService] Reconnect error: $error');
    });

    _socket!.onReconnectFailed((_) {
      _printLog('💀 [SocketService] All reconnect attempts exhausted.');
    });
  }

  void _printLog(String message) {
    debugPrint(message);
    if (kDebugMode) {
      developer.log(message, name: 'SocketService');
    }
  }
}
