import '../entities/tour_entities.dart';

/// Contract implemented by the data layer.
abstract class TourRepository {
  Future<List<TourCategoryEntity>> getCategories();
  Future<List<TourDestinationEntity>> getDestinations();
  Future<List<TourPackageEntity>> getPackages(TourSearchParams params);
  Future<TourPackageEntity> getPackage(String packageId);
  Future<List<TourAddOnEntity>> getAddOns();
  Future<List<TourPackageEntity>> getWishlist();
  Future<List<TourPackageEntity>> toggleWishlist(String packageId);
  Future<TourBookingEntity> createBooking(TourCreateBookingParams params);
  Future<List<TourBookingEntity>> getBookings();
  Future<void> cancelBooking(String bookingId);
}
