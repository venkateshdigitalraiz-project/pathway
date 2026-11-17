import 'dart:async';
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
/// - Broadcasts connection status via [onConnected] stream.
/// - Broadcasts [BOOKING_CREATED] events via [onBookingCreated] stream.
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
  /// Key event for booking creation: send & receive between Flutter app and backend
  static const String eventBookingCreated = 'BOOKING_CREATED';

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

  /// Fires every time a 'BOOKING_CREATED' event is received from the server.
  final _bookingCreatedController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onBookingCreated => _bookingCreatedController.stream;

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
  //  Public API: 2. Emit
  // ──────────────────────────────────────────────

  /// Emits an event on the socket (no-op if not connected).
  void emit(String event, dynamic data) {
    if (!isConnected) {
      _printLog('⚠️ [SocketService] emit("$event") skipped — not connected.');
      return;
    }
    _printLog('🚀 [SocketService] Emitting "$event" with data: $data');
    _socket!.emit(event, data);
  }

  /// Dedicated emit helper for `BOOKING_CREATED`.
  ///
  /// Sends the booking data payload to the backend under the `BOOKING_CREATED` key.
  void emitBookingCreated(dynamic data) {
    emit(eventBookingCreated, data);
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
  }

  // ──────────────────────────────────────────────
  //  Internal helpers
  // ──────────────────────────────────────────────

  void _connectWithToken(String token) {
    try {
      // If already connected, preserve existing socket connection
      if (_socket != null && _socket!.connected) {
        _printLog('⚡ [SocketService] Socket already connected (id: ${_socket?.id}) — preserving session.');
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
      _printLog('✅ [SocketService] Connected successfully — id: ${_socket?.id}');
      _connectedController.add(null);
    });

    // Listen for BOOKING_CREATED broadcast from the backend
    _socket!.on(eventBookingCreated, (data) {
      _printLog('📩 [SocketService] Event "$eventBookingCreated" received from server: $data');
      _bookingCreatedController.add(data);
    });

    _socket!.onDisconnect((reason) {
      final msg = reason?.toString() ?? 'unknown';
      _printLog('❌ [SocketService] Disconnected — reason: $msg');
      _disconnectedController.add(msg);
    });

    _socket!.onConnectError((error) {
      _printLog('❗ [SocketService] Connection error: $error');
    });

    _socket!.onReconnect((attempt) {
      _printLog('🔄 [SocketService] Reconnected after attempt $attempt (id: ${_socket?.id})');
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
