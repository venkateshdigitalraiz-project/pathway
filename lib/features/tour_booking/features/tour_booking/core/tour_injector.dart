import '../data/datasources/tour_mock_data_source.dart';
import '../data/datasources/tour_remote_data_source.dart';
import '../data/repositories/tour_repository_impl.dart';
import '../domain/repositories/tour_repository.dart';
import '../domain/usecases/tour_usecases.dart';
import '../presentation/bloc/tour_booking_bloc.dart';
import '../presentation/bloc/tour_detail_bloc.dart';
import '../presentation/bloc/tour_home_bloc.dart';
import '../presentation/bloc/tour_my_bookings_bloc.dart';
import '../presentation/bloc/tour_packages_bloc.dart';
import '../presentation/bloc/tour_wishlist_bloc.dart';

/// Lightweight manual DI for the Tour Booking module.
/// Swap [TourMockDataSource] for a real API data source here.
class TourInjector {
  TourInjector._();
  static final TourInjector I = TourInjector._();

  late final TourRemoteDataSource _dataSource = TourMockDataSource();
  late final TourRepository _repository = TourRepositoryImpl(_dataSource);

  late final _getCategories = TourGetCategoriesUseCase(_repository);
  late final _getDestinations = TourGetDestinationsUseCase(_repository);
  late final _getPackages = TourGetPackagesUseCase(_repository);
  late final _getPackage = TourGetPackageUseCase(_repository);
  late final _getAddOns = TourGetAddOnsUseCase(_repository);
  late final _getWishlist = TourGetWishlistUseCase(_repository);
  late final _toggleWishlist = TourToggleWishlistUseCase(_repository);
  late final _createBooking = TourCreateBookingUseCase(_repository);
  late final _getBookings = TourGetBookingsUseCase(_repository);
  late final _cancelBooking = TourCancelBookingUseCase(_repository);

  TourHomeBloc homeBloc() => TourHomeBloc(
      getCategories: _getCategories, getDestinations: _getDestinations);
  TourPackagesBloc packagesBloc() => TourPackagesBloc(
      getCategories: _getCategories, getPackages: _getPackages);
  TourDetailBloc detailBloc() => TourDetailBloc(getPackage: _getPackage);
  TourBookingBloc bookingBloc() =>
      TourBookingBloc(getAddOns: _getAddOns, createBooking: _createBooking);
  TourMyBookingsBloc myBookingsBloc() => TourMyBookingsBloc(
      getBookings: _getBookings, cancelBooking: _cancelBooking);
  TourWishlistBloc wishlistBloc() => TourWishlistBloc(
      getWishlist: _getWishlist, toggleWishlist: _toggleWishlist);
}
