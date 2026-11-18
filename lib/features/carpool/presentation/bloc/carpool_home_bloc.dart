import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/socket/socket.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/accepted_booking_entity.dart';
import '../../domain/entities/available_rider_entity.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/accept_booking_usecase.dart';
import '../../domain/usecases/carpool_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../../domain/usecases/reject_booking_usecase.dart';

abstract class CarpoolHomeEvent extends Equatable {
  const CarpoolHomeEvent();
  @override
  List<Object?> get props => [];
}

class CarpoolHomeStarted extends CarpoolHomeEvent {
  const CarpoolHomeStarted();
}

class CarpoolHomeToggleOnlineOffline extends CarpoolHomeEvent {
  final bool isOnline;

  const CarpoolHomeToggleOnlineOffline(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

/// Fired when backend emits `BOOKING_CREATED` socket event from rider side
class CarpoolHomeBookingCreatedReceived extends CarpoolHomeEvent {
  final dynamic bookingData;

  const CarpoolHomeBookingCreatedReceived(this.bookingData);

  @override
  List<Object?> get props => [bookingData];
}

/// Fired when a driver dismisses an available booking card
class CarpoolHomeDismissBooking extends CarpoolHomeEvent {
  final String bookingId;

  const CarpoolHomeDismissBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Fired when a driver declines/rejects a booking with a reason
class CarpoolHomeRejectBookingRequested extends CarpoolHomeEvent {
  final String bookingId;
  final String reason;

  const CarpoolHomeRejectBookingRequested({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Fired when a driver taps "Accept Ride" on a rider booking card
class CarpoolHomeAcceptBookingRequested extends CarpoolHomeEvent {
  final AvailableRiderEntity booking;

  const CarpoolHomeAcceptBookingRequested(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Resets the accepted booking state once consumed by the UI listener
class CarpoolHomeClearAcceptedBooking extends CarpoolHomeEvent {
  const CarpoolHomeClearAcceptedBooking();
}

class CarpoolHomeRouteAdded extends CarpoolHomeEvent {
  final String from;
  final String to;
  final int price;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  const CarpoolHomeRouteAdded({
    required this.from,
    required this.to,
    required this.price,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  @override
  List<Object?> get props => [from, to, price, fromLat, fromLng, toLat, toLng];
}

class CarpoolHomeState extends Equatable {
  const CarpoolHomeState({
    this.status = CarpoolStatus.initial,
    this.user,
    this.routes = const [],
    this.error,
    this.message,
    this.isOnline = true,
    this.availableBookings = const [],
    this.acceptingBookingId,
    this.rejectingBookingId,
    this.acceptedBooking,
    this.acceptedRider,
  });

  final CarpoolStatus status;
  final CarpoolUserEntity? user;
  final List<CarpoolPopularRouteEntity> routes;
  final String? error;
  final String? message;
  final bool isOnline;
  final List<AvailableRiderEntity> availableBookings;
  final String? acceptingBookingId;
  final String? rejectingBookingId;
  final AcceptedBookingEntity? acceptedBooking;
  final AvailableRiderEntity? acceptedRider;

  CarpoolHomeState copyWith({
    CarpoolStatus? status,
    CarpoolUserEntity? user,
    List<CarpoolPopularRouteEntity>? routes,
    String? error,
    String? message,
    bool? isOnline,
    List<AvailableRiderEntity>? availableBookings,
    String? acceptingBookingId,
    bool clearAcceptingBookingId = false,
    String? rejectingBookingId,
    bool clearRejectingBookingId = false,
    AcceptedBookingEntity? acceptedBooking,
    bool clearAcceptedBooking = false,
    AvailableRiderEntity? acceptedRider,
    bool clearAcceptedRider = false,
  }) => CarpoolHomeState(
    status: status ?? this.status,
    user: user ?? this.user,
    routes: routes ?? this.routes,
    error: error,
    message: message,
    isOnline: isOnline ?? this.isOnline,
    availableBookings: availableBookings ?? this.availableBookings,
    acceptingBookingId: clearAcceptingBookingId
        ? null
        : (acceptingBookingId ?? this.acceptingBookingId),
    rejectingBookingId: clearRejectingBookingId
        ? null
        : (rejectingBookingId ?? this.rejectingBookingId),
    acceptedBooking: clearAcceptedBooking
        ? null
        : (acceptedBooking ?? this.acceptedBooking),
    acceptedRider: clearAcceptedRider
        ? null
        : (acceptedRider ?? this.acceptedRider),
  );

  @override
  List<Object?> get props => [
        status,
        user,
        routes,
        error,
        message,
        isOnline,
        availableBookings,
        acceptingBookingId,
        rejectingBookingId,
        acceptedBooking,
        acceptedRider,
      ];
}

class CarpoolHomeBloc extends Bloc<CarpoolHomeEvent, CarpoolHomeState> {
  final CarpoolGetUserUseCase getUser;
  final CarpoolGetPopularRoutesUseCase getPopularRoutes;
  final AcceptBookingUseCase? acceptBooking;
  final RejectBookingUseCase? rejectBooking;
  StreamSubscription<dynamic>? _bookingCreatedSub;

  CarpoolHomeBloc({
    required this.getUser,
    required this.getPopularRoutes,
    this.acceptBooking,
    this.rejectBooking,
  }) : super(const CarpoolHomeState()) {
    on<CarpoolHomeStarted>(_onStarted);
    on<CarpoolHomeToggleOnlineOffline>(_onToggleOnlineOffline);
    on<CarpoolHomeBookingCreatedReceived>(_onBookingCreatedReceived);
    on<CarpoolHomeDismissBooking>(_onDismissBooking);
    on<CarpoolHomeAcceptBookingRequested>(_onAcceptBookingRequested);
    on<CarpoolHomeClearAcceptedBooking>(_onClearAcceptedBooking);
    on<CarpoolHomeRejectBookingRequested>(_onRejectBookingRequested);
    on<CarpoolHomeRouteAdded>(_onRouteAdded);

    // Subscribe to incoming `BOOKING_CREATED` socket events
    _listenToSocketEvents();
  }

  void _listenToSocketEvents() {
    _bookingCreatedSub = SocketService().onBookingCreated.listen((data) {
      debugPrint('⚡ [CarpoolHomeBloc] onBookingCreated stream received event payload: $data');
      add(CarpoolHomeBookingCreatedReceived(data));
    });
  }

  Future<void> _onStarted(
    CarpoolHomeStarted event,
    Emitter<CarpoolHomeState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final results = await Future.wait([
        getUser(const CarpoolNoParams()),
        getPopularRoutes(const CarpoolNoParams()),
      ]);
      final initialOnline = AuthLocalStorage().isDriverOnline();

      // Ensure socket connection is active and driver rooms are joined
      SocketService().ensureConnected().then((_) {
        SocketService().joinDriverRooms();
      });

      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          user: results[0] as CarpoolUserEntity,
          routes: results[1] as List<CarpoolPopularRouteEntity>,
          isOnline: initialOnline,
          availableBookings: const [],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, error: '$e'));
    }
  }

  Future<void> _onToggleOnlineOffline(
    CarpoolHomeToggleOnlineOffline event,
    Emitter<CarpoolHomeState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    await AuthLocalStorage().setDriverOnline(event.isOnline);

    try {
      final driverId = AuthLocalStorage().getUserProfile()?.id ?? '';
      if (event.isOnline) {
        SocketService().emit('driver:online', {'driverId': driverId, 'isOnline': true});
        SocketService().emit('driver_online', {'driverId': driverId, 'isOnline': true});
      } else {
        SocketService().emit('driver:offline', {'driverId': driverId, 'isOnline': false});
        SocketService().emit('driver_offline', {'driverId': driverId, 'isOnline': false});
      }
    } catch (_) {}
  }

  void _onBookingCreatedReceived(
    CarpoolHomeBookingCreatedReceived event,
    Emitter<CarpoolHomeState> emit,
  ) {
    debugPrint('\n══════════════════════════════════════════════════════════════════════════');
    debugPrint('🚗 [CARPOOL HOME BLOC: NEW BOOKING EVENT RECEIVED VIA SOCKET]');
    debugPrint('──────────────────────────────────────────────────────────────────────────');
    debugPrint('   • RAW PAYLOAD: ${event.bookingData}');
    debugPrint('══════════════════════════════════════════════════════════════════════════\n');

    try {
      final currentUserId = AuthLocalStorage().getUserProfile()?.id ??
          AuthLocalStorage().getUserData()?['id']?.toString() ??
          AuthLocalStorage().getUserData()?['_id']?.toString() ??
          '';

      final newRider = AvailableRiderEntity.fromJson(event.bookingData);

      // 1. If the logged in user is the PASSENGER who booked the seat,
      // do not display this event as a driver request on the Publisher Carpool Home page!
      if (currentUserId.isNotEmpty && newRider.passengerId == currentUserId) {
        debugPrint('ℹ️ [CarpoolHomeBloc] Event ignored on Publisher view: logged-in user ($currentUserId) is the passenger.');
        return;
      }

      // 2. If the payload contains publisherId and it does not match current driver, ignore it
      String? publisherId;
      final raw = event.bookingData;
      if (raw is Map) {
        if (raw['ride'] is Map) {
          publisherId = raw['ride']['publisherId']?.toString();
        }
        publisherId ??= raw['publisherId']?.toString();
      }
      if (currentUserId.isNotEmpty &&
          publisherId != null &&
          publisherId.isNotEmpty &&
          publisherId != currentUserId) {
        debugPrint('ℹ️ [CarpoolHomeBloc] Event ignored: ride publisher is $publisherId, but active driver is $currentUserId.');
        return;
      }

      final sb = StringBuffer();
      sb.writeln('\n══════════════════════════════════════════════════════════════════════════');
      sb.writeln('🎉 [CARPOOL HOME BLOC: PARSED RIDER BOOKING CARD DETAILS]');
      sb.writeln('──────────────────────────────────────────────────────────────────────────');
      sb.writeln('   • BOOKING ID    : ${newRider.bookingId}');
      sb.writeln('   • RIDE ID       : ${newRider.rideId}');
      sb.writeln('   • PASSENGER ID  : ${newRider.passengerId}');
      sb.writeln('   • RIDER NAME    : ${newRider.riderName}');
      sb.writeln('   • RIDER PHONE   : ${newRider.riderPhone}');
      sb.writeln('   • RATING        : ⭐ ${newRider.rating} (${newRider.totalRides} trips)');
      sb.writeln('   • FROM (PICKUP) : ${newRider.fromAddress}');
      sb.writeln('   • TO (DROPOFF)  : ${newRider.toAddress}');
      sb.writeln('   • SEATS BOOKED  : ${newRider.seatsBooked} seat(s)');
      sb.writeln('   • TOTAL AMOUNT  : ₹${newRider.totalAmount}');
      sb.writeln('   • VEHICLE       : ${newRider.vehicleModel ?? "Car"} • ${newRider.vehicleNumber ?? "Verified"}');
      sb.writeln('   • DISTANCE / ETA: ${newRider.distanceKm} km • ~${newRider.etaMin} mins away');
      sb.writeln('   • BOOKING TIME  : ${newRider.createdAt.toIso8601String()}');
      sb.writeln('══════════════════════════════════════════════════════════════════════════\n');
      debugPrint(sb.toString());

      final updated = [
        newRider,
        ...state.availableBookings.where((b) => b.bookingId != newRider.bookingId),
      ];
      emit(state.copyWith(
        availableBookings: updated,
        isOnline: true,
      ));
      debugPrint('✅ [CarpoolHomeBloc] Live booking card added to UI! Total active cards: ${updated.length}');
    } catch (e, stack) {
      debugPrint('❌ [CarpoolHomeBloc] ERROR PARSING BOOKING EVENT: $e');
      debugPrint('   STACKTRACE:\n$stack');
    }
  }

  void _onDismissBooking(
    CarpoolHomeDismissBooking event,
    Emitter<CarpoolHomeState> emit,
  ) {
    final updated = state.availableBookings
        .where((b) => b.bookingId != event.bookingId)
        .toList();
    emit(state.copyWith(availableBookings: updated));
  }

  Future<void> _onAcceptBookingRequested(
    CarpoolHomeAcceptBookingRequested event,
    Emitter<CarpoolHomeState> emit,
  ) async {
    final booking = event.booking;
    emit(state.copyWith(acceptingBookingId: booking.bookingId, error: null));

    try {
      final useCase = acceptBooking ??
          AcceptBookingUseCase(CarpoolRepositoryImpl(CarpoolMockDataSource()));
      final accepted = await useCase.call(booking.bookingId);

      // Remove accepted booking from available list
      final updatedList = state.availableBookings
          .where((b) => b.bookingId != booking.bookingId)
          .toList();

      emit(state.copyWith(
        clearAcceptingBookingId: true,
        availableBookings: updatedList,
        acceptedBooking: accepted,
        acceptedRider: booking,
      ));
    } catch (e) {
      emit(state.copyWith(
        clearAcceptingBookingId: true,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onClearAcceptedBooking(
    CarpoolHomeClearAcceptedBooking event,
    Emitter<CarpoolHomeState> emit,
  ) {
    emit(state.copyWith(
      clearAcceptedBooking: true,
      clearAcceptedRider: true,
    ));
  }

  Future<void> _onRejectBookingRequested(
    CarpoolHomeRejectBookingRequested event,
    Emitter<CarpoolHomeState> emit,
  ) async {
    emit(state.copyWith(rejectingBookingId: event.bookingId, error: null));

    try {
      final useCase = rejectBooking ??
          RejectBookingUseCase(CarpoolRepositoryImpl(CarpoolMockDataSource()));
      await useCase.call(bookingId: event.bookingId, reason: event.reason);

      // Remove declined booking from available list
      final updatedList = state.availableBookings
          .where((b) => b.bookingId != event.bookingId)
          .toList();

      emit(state.copyWith(
        clearRejectingBookingId: true,
        availableBookings: updatedList,
        message: 'Booking request declined',
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        clearRejectingBookingId: true,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onRouteAdded(
    CarpoolHomeRouteAdded event,
    Emitter<CarpoolHomeState> emit,
  ) {
    final newRoute = CarpoolPopularRouteEntity(
      from: event.from,
      to: event.to,
      price: event.price,
      fromLat: event.fromLat,
      fromLng: event.fromLng,
      toLat: event.toLat,
      toLng: event.toLng,
    );
    final updatedRoutes = [
      newRoute,
      ...state.routes.where(
        (r) => !(r.from.toLowerCase() == event.from.toLowerCase() &&
            r.to.toLowerCase() == event.to.toLowerCase()),
      ),
    ];
    emit(state.copyWith(routes: updatedRoutes));
  }

  @override
  Future<void> close() {
    _bookingCreatedSub?.cancel();
    return super.close();
  }
}
