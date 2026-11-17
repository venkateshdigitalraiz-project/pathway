import '../entities/accepted_booking_entity.dart';
import '../repositories/carpool_repository.dart';

class AcceptBookingUseCase {
  final CarpoolRepository repository;

  AcceptBookingUseCase(this.repository);

  Future<AcceptedBookingEntity> call(String bookingId) {
    return repository.acceptBooking(bookingId);
  }
}
