import '../repositories/carpool_repository.dart';

class RejectBookingUseCase {
  final CarpoolRepository repository;

  RejectBookingUseCase(this.repository);

  Future<void> call({required String bookingId, required String reason}) {
    return repository.rejectBooking(bookingId, reason);
  }
}
