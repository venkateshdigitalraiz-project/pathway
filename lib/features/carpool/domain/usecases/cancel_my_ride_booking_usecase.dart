import '../repositories/my_ride_booking_repository.dart';

class CancelMyRideBookingUseCase {
  final MyRideBookingRepository repository;
  const CancelMyRideBookingUseCase(this.repository);

  Future<void> call(String bookingId, {String? reason}) =>
      repository.cancelBooking(bookingId, reason: reason);
}
