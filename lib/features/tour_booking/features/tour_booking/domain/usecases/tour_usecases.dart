import '../entities/tour_entities.dart';
import '../repositories/tour_repository.dart';
import 'tour_usecase.dart';

class TourGetCategoriesUseCase
    implements TourUseCase<List<TourCategoryEntity>, TourNoParams> {
  const TourGetCategoriesUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourCategoryEntity>> call(TourNoParams params) =>
      _repository.getCategories();
}

class TourGetDestinationsUseCase
    implements TourUseCase<List<TourDestinationEntity>, TourNoParams> {
  const TourGetDestinationsUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourDestinationEntity>> call(TourNoParams params) =>
      _repository.getDestinations();
}

class TourGetPackagesUseCase
    implements TourUseCase<List<TourPackageEntity>, TourSearchParams> {
  const TourGetPackagesUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourPackageEntity>> call(TourSearchParams params) =>
      _repository.getPackages(params);
}

class TourGetPackageUseCase implements TourUseCase<TourPackageEntity, String> {
  const TourGetPackageUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<TourPackageEntity> call(String packageId) =>
      _repository.getPackage(packageId);
}

class TourGetAddOnsUseCase
    implements TourUseCase<List<TourAddOnEntity>, TourNoParams> {
  const TourGetAddOnsUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourAddOnEntity>> call(TourNoParams params) =>
      _repository.getAddOns();
}

class TourGetWishlistUseCase
    implements TourUseCase<List<TourPackageEntity>, TourNoParams> {
  const TourGetWishlistUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourPackageEntity>> call(TourNoParams params) =>
      _repository.getWishlist();
}

class TourToggleWishlistUseCase
    implements TourUseCase<List<TourPackageEntity>, String> {
  const TourToggleWishlistUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourPackageEntity>> call(String packageId) =>
      _repository.toggleWishlist(packageId);
}

class TourCreateBookingUseCase
    implements TourUseCase<TourBookingEntity, TourCreateBookingParams> {
  const TourCreateBookingUseCase(this._repository);
  final TourRepository _repository;

  @override
  Future<TourBookingEntity> call(TourCreateBookingParams p) {
    if (p.customerName.trim().length < 2) {
      throw const TourFailure('Enter your full name.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(p.email.trim())) {
      throw const TourFailure('Enter a valid email address.');
    }
    if (p.phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      throw const TourFailure('Enter a valid 10-digit mobile number.');
    }
    if (p.travellers < 1) {
      throw const TourFailure('Add at least one traveller.');
    }
    return _repository.createBooking(p);
  }
}

class TourGetBookingsUseCase
    implements TourUseCase<List<TourBookingEntity>, TourNoParams> {
  const TourGetBookingsUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<List<TourBookingEntity>> call(TourNoParams params) =>
      _repository.getBookings();
}

class TourCancelBookingUseCase implements TourUseCase<void, String> {
  const TourCancelBookingUseCase(this._repository);
  final TourRepository _repository;
  @override
  Future<void> call(String bookingId) => _repository.cancelBooking(bookingId);
}
