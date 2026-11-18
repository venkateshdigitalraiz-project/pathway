import '../entities/accepted_booking_entity.dart';
import '../entities/carpool_entities.dart';
import '../entities/carpool_pricing_entity.dart';
import '../entities/rejected_booking_entity.dart';
import '../usecases/carpool_calculate_pricing_usecase.dart';

/// Contract implemented by the data layer. The domain never depends on data.
abstract class CarpoolRepository {
  Future<CarpoolUserEntity> getUser();
  Future<List<CarpoolPopularRouteEntity>> getPopularRoutes();
  Future<List<CarpoolRideEntity>> searchRides(CarpoolSearchRidesParams params);
  Future<void> bookRide(String rideId);
  Future<AcceptedBookingEntity> acceptBooking(String bookingId);
  Future<RejectedBookingEntity> rejectBooking(String bookingId, String reason);
  Future<CarpoolRideEntity> publishRide(CarpoolPublishRideParams params);
  Future<List<CarpoolRideEntity>> getMyRides();
  Future<void> cancelRide(String rideId);
  Future<CarpoolWalletEntity> getWallet();
  Future<CarpoolWalletEntity> addMoney(double amount);
  Future<List<CarpoolMessageEntity>> getMessages();
  Future<CarpoolPricingEntity> calculatePricing(
    CarpoolCalculatePricingParams params,
  );
}
