import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecase.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourMyBookingsEvent extends Equatable {
  const TourMyBookingsEvent();
  @override
  List<Object?> get props => [];
}

class TourMyBookingsStarted extends TourMyBookingsEvent {
  const TourMyBookingsStarted();
}

class TourMyBookingsTabChanged extends TourMyBookingsEvent {
  const TourMyBookingsTabChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class TourMyBookingsCancelPressed extends TourMyBookingsEvent {
  const TourMyBookingsCancelPressed(this.bookingId);
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class TourMyBookingsState extends Equatable {
  const TourMyBookingsState({
    this.status = TourStatus.initial,
    this.tabIndex = 0,
    this.bookings = const [],
    this.message,
  });

  final TourStatus status;
  final int tabIndex; // 0 Upcoming, 1 Past, 2 Cancelled
  final List<TourBookingEntity> bookings;
  final String? message;

  List<TourBookingEntity> get visible => bookings.where((b) {
        switch (tabIndex) {
          case 0:
            return b.isUpcoming;
          case 1:
            return b.isPast;
          default:
            return b.isCancelled;
        }
      }).toList();

  TourMyBookingsState copyWith({
    TourStatus? status,
    int? tabIndex,
    List<TourBookingEntity>? bookings,
    String? message,
  }) =>
      TourMyBookingsState(
        status: status ?? this.status,
        tabIndex: tabIndex ?? this.tabIndex,
        bookings: bookings ?? this.bookings,
        message: message,
      );

  @override
  List<Object?> get props => [status, tabIndex, bookings, message];
}

class TourMyBookingsBloc
    extends Bloc<TourMyBookingsEvent, TourMyBookingsState> {
  TourMyBookingsBloc({
    required TourGetBookingsUseCase getBookings,
    required TourCancelBookingUseCase cancelBooking,
  })  : _getBookings = getBookings,
        _cancelBooking = cancelBooking,
        super(const TourMyBookingsState()) {
    on<TourMyBookingsStarted>(_onStarted);
    on<TourMyBookingsTabChanged>(
        (e, emit) => emit(state.copyWith(tabIndex: e.index)));
    on<TourMyBookingsCancelPressed>(_onCancel);
  }

  final TourGetBookingsUseCase _getBookings;
  final TourCancelBookingUseCase _cancelBooking;

  Future<void> _onStarted(
      TourMyBookingsStarted e, Emitter<TourMyBookingsState> emit) async {
    emit(state.copyWith(status: TourStatus.loading));
    try {
      final list = await _getBookings(const TourNoParams());
      emit(state.copyWith(status: TourStatus.success, bookings: list));
    } catch (_) {
      emit(state.copyWith(status: TourStatus.failure));
    }
  }

  Future<void> _onCancel(TourMyBookingsCancelPressed e,
      Emitter<TourMyBookingsState> emit) async {
    try {
      await _cancelBooking(e.bookingId);
      final list = await _getBookings(const TourNoParams());
      emit(state.copyWith(
          status: TourStatus.success,
          bookings: list,
          message: 'Booking cancelled'));
    } catch (_) {
      emit(state.copyWith(message: 'Could not cancel the booking'));
    }
    emit(state.copyWith()); // clears the one-shot message
  }
}
