import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/cancel_my_ride_booking_usecase.dart';
import '../../domain/usecases/get_my_ride_bookings_usecase.dart';

// ── Events ─────────────────────────────────────────────────────────────
abstract class MyRideBookingEvent extends Equatable {
  const MyRideBookingEvent();
  @override
  List<Object?> get props => [];
}

class MyRideBookingStarted extends MyRideBookingEvent {
  const MyRideBookingStarted();
}

class MyRideBookingTabChanged extends MyRideBookingEvent {
  final int index;
  const MyRideBookingTabChanged(this.index);
  @override
  List<Object?> get props => [index];
}

class MyRideBookingSearchQueryChanged extends MyRideBookingEvent {
  final String query;
  const MyRideBookingSearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class MyRideBookingCancelRequested extends MyRideBookingEvent {
  final String bookingId;
  final String? reason;
  const MyRideBookingCancelRequested(this.bookingId, {this.reason});
  @override
  List<Object?> get props => [bookingId, reason];
}

class MyRideBookingRefreshed extends MyRideBookingEvent {
  const MyRideBookingRefreshed();
}

// ── State ──────────────────────────────────────────────────────────────
class MyRideBookingState extends Equatable {
  final CarpoolStatus status;
  final int tabIndex; // 0: All, 1: Active, 2: Completed, 3: Cancelled
  final String searchQuery;
  final List<RiderBookingEntity> bookings;
  final String? cancellingBookingId;
  final String? message;

  const MyRideBookingState({
    this.status = CarpoolStatus.initial,
    this.tabIndex = 0,
    this.searchQuery = '',
    this.bookings = const [],
    this.cancellingBookingId,
    this.message,
  });

  List<RiderBookingEntity> get activeBookings =>
      bookings.where((b) => b.status == RiderBookingStatus.confirmed).toList();

  List<RiderBookingEntity> get completedBookings =>
      bookings.where((b) => b.status == RiderBookingStatus.completed).toList();

  List<RiderBookingEntity> get cancelledBookings =>
      bookings.where((b) => b.status == RiderBookingStatus.cancelled).toList();

  int get activeCount => activeBookings.length;
  int get completedCount => completedBookings.length;
  int get cancelledCount => cancelledBookings.length;
  int get totalCount => bookings.length;

  int get totalFareSpent => bookings
      .where((b) => b.status != RiderBookingStatus.cancelled)
      .fold<int>(0, (sum, b) => sum + b.totalAmount);

  List<RiderBookingEntity> get filteredBookings {
    List<RiderBookingEntity> list;
    switch (tabIndex) {
      case 1:
        list = activeBookings;
        break;
      case 2:
        list = completedBookings;
        break;
      case 3:
        list = cancelledBookings;
        break;
      case 0:
      default:
        list = bookings;
        break;
    }

    if (searchQuery.trim().isEmpty) return list;

    final q = searchQuery.toLowerCase().trim();
    return list.where((b) {
      return b.from.toLowerCase().contains(q) ||
          b.to.toLowerCase().contains(q) ||
          b.driverName.toLowerCase().contains(q) ||
          b.vehicle.toLowerCase().contains(q);
    }).toList();
  }

  MyRideBookingState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    String? searchQuery,
    List<RiderBookingEntity>? bookings,
    String? cancellingBookingId,
    bool clearCancelling = false,
    String? message,
  }) {
    return MyRideBookingState(
      status: status ?? this.status,
      tabIndex: tabIndex ?? this.tabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      bookings: bookings ?? this.bookings,
      cancellingBookingId: clearCancelling
          ? null
          : (cancellingBookingId ?? this.cancellingBookingId),
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tabIndex,
        searchQuery,
        bookings,
        cancellingBookingId,
        message,
      ];
}

// ── BLoC ───────────────────────────────────────────────────────────────
class MyRideBookingBloc
    extends Bloc<MyRideBookingEvent, MyRideBookingState> {
  final GetMyRideBookingsUseCase getMyBookings;
  final CancelMyRideBookingUseCase cancelBooking;

  MyRideBookingBloc({
    required this.getMyBookings,
    required this.cancelBooking,
  }) : super(const MyRideBookingState()) {
    on<MyRideBookingStarted>(_onStarted);
    on<MyRideBookingTabChanged>(_onTabChanged);
    on<MyRideBookingSearchQueryChanged>(_onSearchQueryChanged);
    on<MyRideBookingCancelRequested>(_onCancelBooking);
    on<MyRideBookingRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    MyRideBookingStarted event,
    Emitter<MyRideBookingState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final list = await getMyBookings();
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          bookings: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CarpoolStatus.failure,
          message: 'Failed to load bookings: $e',
        ),
      );
    }
  }

  void _onTabChanged(
    MyRideBookingTabChanged event,
    Emitter<MyRideBookingState> emit,
  ) {
    emit(state.copyWith(tabIndex: event.index));
  }

  void _onSearchQueryChanged(
    MyRideBookingSearchQueryChanged event,
    Emitter<MyRideBookingState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onCancelBooking(
    MyRideBookingCancelRequested event,
    Emitter<MyRideBookingState> emit,
  ) async {
    emit(state.copyWith(cancellingBookingId: event.bookingId));
    try {
      await cancelBooking(event.bookingId, reason: event.reason);
      final list = await getMyBookings();
      emit(
        state.copyWith(
          clearCancelling: true,
          bookings: list,
          message: 'Booking cancelled successfully.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          clearCancelling: true,
          message: 'Cancel failed: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    MyRideBookingRefreshed event,
    Emitter<MyRideBookingState> emit,
  ) async {
    try {
      final list = await getMyBookings();
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          bookings: list,
        ),
      );
    } catch (_) {}
  }
}
