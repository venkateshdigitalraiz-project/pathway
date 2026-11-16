import '../entities/rider_booking_entity.dart';

abstract class MyRideBookingRepository {
  Future<List<RiderBookingEntity>> getMyRideBookings();
  Future<void> cancelBooking(String bookingId, {String? reason});
}
