import '../entities/rider_booking_entity.dart';

abstract class MyRideBookingRepository {
  Future<List<RiderBookingEntity>> getMyRideBookings();
  Future<String?> cancelBooking(String bookingId, {String? reason});
}
