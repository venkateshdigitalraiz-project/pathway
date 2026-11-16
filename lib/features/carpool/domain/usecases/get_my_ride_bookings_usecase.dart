import '../entities/rider_booking_entity.dart';
import '../repositories/my_ride_booking_repository.dart';

class GetMyRideBookingsUseCase {
  final MyRideBookingRepository repository;
  const GetMyRideBookingsUseCase(this.repository);

  Future<List<RiderBookingEntity>> call() => repository.getMyRideBookings();
}
