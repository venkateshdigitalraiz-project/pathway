import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/accepted_booking_entity.dart';
import '../../domain/entities/my_publish_ride_details_entity.dart';
import '../../domain/entities/rejected_booking_entity.dart';
import '../../domain/usecases/accept_booking_usecase.dart';
import '../../domain/usecases/get_my_publish_ride_details_usecase.dart';
import '../../domain/usecases/reject_booking_usecase.dart';

abstract class MyPublishRideDetailsEvent extends Equatable {
  const MyPublishRideDetailsEvent();

  @override
  List<Object?> get props => [];
}

class MyPublishRideDetailsFetchRequested extends MyPublishRideDetailsEvent {
  final String rideId;

  const MyPublishRideDetailsFetchRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class MyPublishRideDetailsRefreshRequested extends MyPublishRideDetailsEvent {
  final String rideId;

  const MyPublishRideDetailsRefreshRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class MyPublishRideDetailsAcceptBookingRequested
    extends MyPublishRideDetailsEvent {
  final String rideId;
  final String bookingId;

  const MyPublishRideDetailsAcceptBookingRequested({
    required this.rideId,
    required this.bookingId,
  });

  @override
  List<Object?> get props => [rideId, bookingId];
}

class MyPublishRideDetailsRejectBookingRequested
    extends MyPublishRideDetailsEvent {
  final String rideId;
  final String bookingId;
  final String reason;

  const MyPublishRideDetailsRejectBookingRequested({
    required this.rideId,
    required this.bookingId,
    this.reason = 'Rejected by driver',
  });

  @override
  List<Object?> get props => [rideId, bookingId, reason];
}

abstract class MyPublishRideDetailsState extends Equatable {
  const MyPublishRideDetailsState();

  @override
  List<Object?> get props => [];
}

class MyPublishRideDetailsInitial extends MyPublishRideDetailsState {
  const MyPublishRideDetailsInitial();
}

class MyPublishRideDetailsLoading extends MyPublishRideDetailsState {
  const MyPublishRideDetailsLoading();
}

class MyPublishRideDetailsLoaded extends MyPublishRideDetailsState {
  final MyPublishRideDetailsEntity details;
  final String? processingBookingId;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const MyPublishRideDetailsLoaded(
    this.details, {
    this.processingBookingId,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  @override
  List<Object?> get props => [
        details,
        processingBookingId,
        feedbackMessage,
        isErrorFeedback,
      ];

  MyPublishRideDetailsLoaded copyWith({
    MyPublishRideDetailsEntity? details,
    String? processingBookingId,
    String? feedbackMessage,
    bool? isErrorFeedback,
    bool clearProcessing = false,
  }) {
    return MyPublishRideDetailsLoaded(
      details ?? this.details,
      processingBookingId: clearProcessing
          ? null
          : (processingBookingId ?? this.processingBookingId),
      feedbackMessage: feedbackMessage,
      isErrorFeedback: isErrorFeedback ?? false,
    );
  }
}

class MyPublishRideDetailsFailure extends MyPublishRideDetailsState {
  final String error;

  const MyPublishRideDetailsFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class MyPublishRideDetailsBloc
    extends Bloc<MyPublishRideDetailsEvent, MyPublishRideDetailsState> {
  final GetMyPublishRideDetailsUseCase getPublishRideDetails;
  final AcceptBookingUseCase? acceptBooking;
  final RejectBookingUseCase? rejectBooking;

  MyPublishRideDetailsBloc({
    required this.getPublishRideDetails,
    this.acceptBooking,
    this.rejectBooking,
  }) : super(const MyPublishRideDetailsInitial()) {
    on<MyPublishRideDetailsFetchRequested>(_onFetch);
    on<MyPublishRideDetailsRefreshRequested>(_onRefresh);
    on<MyPublishRideDetailsAcceptBookingRequested>(_onAcceptBooking);
    on<MyPublishRideDetailsRejectBookingRequested>(_onRejectBooking);
  }

  Future<void> _onFetch(
    MyPublishRideDetailsFetchRequested event,
    Emitter<MyPublishRideDetailsState> emit,
  ) async {
    emit(const MyPublishRideDetailsLoading());
    try {
      final details = await getPublishRideDetails(event.rideId);
      emit(MyPublishRideDetailsLoaded(details));
    } catch (e) {
      emit(MyPublishRideDetailsFailure(
        e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefresh(
    MyPublishRideDetailsRefreshRequested event,
    Emitter<MyPublishRideDetailsState> emit,
  ) async {
    try {
      final details = await getPublishRideDetails(event.rideId);
      emit(MyPublishRideDetailsLoaded(details));
    } catch (e) {
      if (state is! MyPublishRideDetailsLoaded) {
        emit(MyPublishRideDetailsFailure(
          e.toString().replaceAll('Exception: ', ''),
        ));
      }
    }
  }

  Future<void> _onAcceptBooking(
    MyPublishRideDetailsAcceptBookingRequested event,
    Emitter<MyPublishRideDetailsState> emit,
  ) async {
    final current = state;
    if (current is MyPublishRideDetailsLoaded) {
      emit(current.copyWith(processingBookingId: event.bookingId));
    }
    try {
      final useCase = acceptBooking ??
          AcceptBookingUseCase(CarpoolRepositoryImpl(CarpoolMockDataSource()));
      final AcceptedBookingEntity acceptedBooking =
          await useCase(event.bookingId);

      // Optimistically update the booking in the loaded state with the API response
      if (state is MyPublishRideDetailsLoaded) {
        final currentLoaded = state as MyPublishRideDetailsLoaded;
        final updatedBookings = currentLoaded.details.bookings.map((b) {
          if (b.id == event.bookingId) {
            return b.copyWith(
              bookingStatus: acceptedBooking.bookingStatus,
              paymentStatus: acceptedBooking.paymentStatus,
              totalAmount: acceptedBooking.totalAmount > 0
                  ? acceptedBooking.totalAmount
                  : b.totalAmount,
            );
          }
          return b;
        }).toList();

        final updatedDetails = currentLoaded.details.copyWith(
          bookings: updatedBookings,
          availableSeats: acceptedBooking.availableSeats > 0
              ? acceptedBooking.availableSeats
              : currentLoaded.details.availableSeats,
        );

        emit(MyPublishRideDetailsLoaded(
          updatedDetails,
          feedbackMessage: acceptedBooking.message.isNotEmpty
              ? acceptedBooking.message
              : 'Booking accepted successfully',
          isErrorFeedback: false,
        ));
      }

      // Sync fresh details from the backend
      final fresh = await getPublishRideDetails(event.rideId);
      emit(MyPublishRideDetailsLoaded(
        fresh,
        feedbackMessage: acceptedBooking.message.isNotEmpty
            ? acceptedBooking.message
            : 'Booking accepted successfully',
        isErrorFeedback: false,
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (state is MyPublishRideDetailsLoaded) {
        emit((state as MyPublishRideDetailsLoaded).copyWith(
          clearProcessing: true,
          feedbackMessage: errorMsg,
          isErrorFeedback: true,
        ));
      }
    }
  }

  Future<void> _onRejectBooking(
    MyPublishRideDetailsRejectBookingRequested event,
    Emitter<MyPublishRideDetailsState> emit,
  ) async {
    final current = state;
    if (current is MyPublishRideDetailsLoaded) {
      emit(current.copyWith(processingBookingId: event.bookingId));
    }
    try {
      final useCase = rejectBooking ??
          RejectBookingUseCase(CarpoolRepositoryImpl(CarpoolMockDataSource()));
      final RejectedBookingEntity rejectedBooking =
          await useCase(bookingId: event.bookingId, reason: event.reason);

      if (state is MyPublishRideDetailsLoaded) {
        final currentLoaded = state as MyPublishRideDetailsLoaded;
        final updatedBookings = currentLoaded.details.bookings.map((b) {
          if (b.id == event.bookingId) {
            return b.copyWith(bookingStatus: rejectedBooking.bookingStatus);
          }
          return b;
        }).toList();

        final updatedDetails = currentLoaded.details.copyWith(
          bookings: updatedBookings,
          availableSeats: rejectedBooking.availableSeats > 0
              ? rejectedBooking.availableSeats
              : currentLoaded.details.availableSeats,
        );

        emit(MyPublishRideDetailsLoaded(
          updatedDetails,
          feedbackMessage: rejectedBooking.message.isNotEmpty
              ? rejectedBooking.message
              : 'Booking request declined',
          isErrorFeedback: false,
        ));
      }

      final fresh = await getPublishRideDetails(event.rideId);
      emit(MyPublishRideDetailsLoaded(
        fresh,
        feedbackMessage: rejectedBooking.message.isNotEmpty
            ? rejectedBooking.message
            : 'Booking request declined',
        isErrorFeedback: false,
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (state is MyPublishRideDetailsLoaded) {
        emit((state as MyPublishRideDetailsLoaded).copyWith(
          clearProcessing: true,
          feedbackMessage: errorMsg,
          isErrorFeedback: true,
        ));
      }
    }
  }
}
