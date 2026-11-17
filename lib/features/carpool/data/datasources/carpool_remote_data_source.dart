import '../../domain/entities/accepted_booking_entity.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/carpool_pricing_entity.dart';
import '../../domain/usecases/carpool_calculate_pricing_usecase.dart';
import '../models/carpool_models.dart';

abstract class CarpoolRemoteDataSource {
  Future<CarpoolUserModel> fetchUser();
  Future<List<CarpoolPopularRouteModel>> fetchPopularRoutes();
  Future<List<CarpoolRideModel>> searchRides(CarpoolSearchRidesParams params);
  Future<void> bookRide(String rideId);
  Future<AcceptedBookingEntity> acceptBooking(String bookingId);
  Future<void> rejectBooking(String bookingId, String reason);
  Future<CarpoolRideModel> publishRide(CarpoolPublishRideParams params);
  Future<List<CarpoolRideModel>> fetchMyRides();
  Future<void> cancelRide(String rideId);
  Future<CarpoolWalletModel> fetchWallet();
  Future<CarpoolWalletModel> addMoney(double amount);
  Future<List<CarpoolMessageModel>> fetchMessages();
  Future<CarpoolPricingEntity> calculatePricing(
    CarpoolCalculatePricingParams params,
  );
}
