import '../../domain/entities/tour_entities.dart';
import '../../domain/repositories/tour_repository.dart';
import '../datasources/tour_remote_data_source.dart';

class TourRepositoryImpl implements TourRepository {
  const TourRepositoryImpl(this._remote);
  final TourRemoteDataSource _remote;

  @override
  Future<List<TourCategoryEntity>> getCategories() => _remote.fetchCategories();

  @override
  Future<List<TourDestinationEntity>> getDestinations() =>
      _remote.fetchDestinations();

  @override
  Future<List<TourPackageEntity>> getPackages(TourSearchParams params) =>
      _remote.fetchPackages(params);

  @override
  Future<TourPackageEntity> getPackage(String packageId) =>
      _remote.fetchPackage(packageId);

  @override
  Future<List<TourAddOnEntity>> getAddOns() => _remote.fetchAddOns();

  @override
  Future<List<TourPackageEntity>> getWishlist() => _remote.fetchWishlist();

  @override
  Future<List<TourPackageEntity>> toggleWishlist(String packageId) =>
      _remote.toggleWishlist(packageId);

  @override
  Future<TourBookingEntity> createBooking(TourCreateBookingParams params) =>
      _remote.createBooking(params);

  @override
  Future<List<TourBookingEntity>> getBookings() => _remote.fetchBookings();

  @override
  Future<void> cancelBooking(String bookingId) =>
      _remote.cancelBooking(bookingId);
}
