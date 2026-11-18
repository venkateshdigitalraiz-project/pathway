import '../entities/rejected_booking_entity.dart';
import '../repositories/carpool_repository.dart';

class RejectBookingUseCase {
  final CarpoolRepository repository;

  RejectBookingUseCase(this.repository);

  Future<RejectedBookingEntity> call({
    required String bookingId,
    required String reason,
  }) {
    return repository.rejectBooking(bookingId, reason);
  }
}
