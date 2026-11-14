import '../../domain/entities/tour_entities.dart';
import '../models/tour_models.dart';

abstract class TourRemoteDataSource {
  Future<List<TourCategoryModel>> fetchCategories();
  Future<List<TourDestinationModel>> fetchDestinations();
  Future<List<TourPackageModel>> fetchPackages(TourSearchParams params);
  Future<TourPackageModel> fetchPackage(String packageId);
  Future<List<TourAddOnModel>> fetchAddOns();
  Future<List<TourPackageModel>> fetchWishlist();
  Future<List<TourPackageModel>> toggleWishlist(String packageId);
  Future<TourBookingModel> createBooking(TourCreateBookingParams params);
  Future<List<TourBookingModel>> fetchBookings();
  Future<void> cancelBooking(String bookingId);
}
