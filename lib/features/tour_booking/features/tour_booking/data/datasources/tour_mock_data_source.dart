import 'package:intl/intl.dart';

import '../../domain/entities/tour_entities.dart';
import '../models/tour_models.dart';
import 'tour_remote_data_source.dart';

/// In-memory implementation so the module runs without a backend.
/// Swap for an API-backed [TourRemoteDataSource] in `TourInjector`.
/// Add photo URLs to `imageUrls` / `imageUrl` when you have them.
class TourMockDataSource implements TourRemoteDataSource {
  TourMockDataSource() {
    final now = DateTime.now();
    DateTime day(int offset) =>
        DateTime(now.year, now.month, now.day + offset);

    TourBookingModel seed(String id, String ref, TourPackageModel p, int offset,
            int travellers, TourBookingStatus status) =>
        TourBookingModel(
          id: id,
          reference: ref,
          package: p,
          travelDate: day(offset),
          travellers: travellers,
          packageType: TourPackageType.standard,
          addOnIds: const [],
          totalAmount: p.price * travellers,
          status: status,
          customerName: 'Traveler',
          email: '',
          phone: '',
          notes: '',
          paymentMethod: TourPaymentMethod.upi,
        );

    _bookings = [
      seed('b1', 'TC202511151234', _packages[0], 12, 2,
          TourBookingStatus.confirmed),
      seed('b2', 'TC202509030871', _packages[2], -40, 3,
          TourBookingStatus.completed),
      seed('b3', 'TC202510120456', _packages[3], 30, 2,
          TourBookingStatus.cancelled),
    ];
  }

  static const _categories = [
    TourCategoryModel(id: 'international', name: 'International'),
    TourCategoryModel(id: 'domestic', name: 'Domestic'),
    TourCategoryModel(id: 'honeymoon', name: 'Honeymoon'),
    TourCategoryModel(id: 'weekend', name: 'Weekend Getaway'),
  ];

  static const _destinations = [
    TourDestinationModel(id: 'd1', name: 'Bali', fromPrice: 49999, packageId: 'p5'),
    TourDestinationModel(id: 'd2', name: 'Dubai', fromPrice: 52999, packageId: 'p6'),
    TourDestinationModel(id: 'd3', name: 'Switzerland', fromPrice: 89999, packageId: 'p7'),
  ];

  static const _addOns = [
    TourAddOnModel(id: 'insurance', name: 'Travel Insurance', price: 499, perPerson: true),
    TourAddOnModel(id: 'pickup', name: 'Airport Pickup', price: 999, perPerson: false),
  ];

  static const _packages = <TourPackageModel>[
    TourPackageModel(
      id: 'p1', title: 'Maldives Getaway', location: 'Maldives',
      nights: 5, days: 6, rating: 4.8, reviewCount: 2568,
      price: 59999, premiumPrice: 74999, originalPrice: 74999,
      description:
          'Experience paradise with our exclusive Maldives tour package. Enjoy crystal clear waters, luxurious resorts and breathtaking sunsets.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Stay in premium beach resort',
        'Snorkeling & water sports',
        'Sunset cruise',
        'Candlelight dinner on the beach',
      ],
      categoryIds: ['international', 'honeymoon'],
    ),
    TourPackageModel(
      id: 'p2', title: 'Europe Highlights', location: 'France, Switzerland',
      nights: 7, days: 8, rating: 4.7, reviewCount: 1800,
      price: 124999, premiumPrice: 149999, originalPrice: 149999,
      description:
          'See the best of Europe in one trip: the Eiffel Tower in Paris, the Swiss Alps and charming old towns, with comfortable stays and guided tours.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Eiffel Tower summit access',
        'Swiss Alps scenic train',
        'Seine river cruise',
        'Guided city tours',
      ],
      categoryIds: ['international'],
    ),
    TourPackageModel(
      id: 'p3', title: 'Kerala Bliss', location: 'Kerala',
      nights: 4, days: 5, rating: 4.6, reviewCount: 1200,
      price: 24999, premiumPrice: 32999, originalPrice: 29999,
      description:
          'Drift through the backwaters on a houseboat, walk through tea gardens in Munnar and relax on golden beaches.',
      includesFlights: false, includesHotels: true, includesTransfers: true,
      highlights: [
        'Private houseboat stay',
        'Munnar tea garden walk',
        'Kathakali evening show',
        'Ayurvedic spa session',
      ],
      categoryIds: ['domestic', 'honeymoon', 'weekend'],
    ),
    TourPackageModel(
      id: 'p4', title: 'Singapore Tour', location: 'Singapore',
      nights: 4, days: 5, rating: 4.8, reviewCount: 1100,
      price: 42999, premiumPrice: 54999, originalPrice: 49999,
      description:
          'Discover the Lion City: Marina Bay, Gardens by the Bay, Sentosa and the Night Safari, all with easy transfers.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Gardens by the Bay light show',
        'Sentosa island day',
        'Night Safari',
        'Marina Bay skyline walk',
      ],
      categoryIds: ['international', 'weekend'],
    ),
    TourPackageModel(
      id: 'p5', title: 'Bali Escape', location: 'Bali, Indonesia',
      nights: 5, days: 6, rating: 4.7, reviewCount: 1500,
      price: 49999, premiumPrice: 63999, originalPrice: 59999,
      description:
          'Temples, rice terraces and beach clubs. Bali blends culture and relaxation with private villas and curated experiences.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Ubud rice terrace trek',
        'Uluwatu temple sunset',
        'Nusa Penida day trip',
        'Private pool villa',
      ],
      categoryIds: ['international', 'honeymoon'],
    ),
    TourPackageModel(
      id: 'p6', title: 'Dubai Delight', location: 'Dubai, UAE',
      nights: 4, days: 5, rating: 4.6, reviewCount: 2200,
      price: 52999, premiumPrice: 66999, originalPrice: 62999,
      description:
          'Skyscrapers, desert safaris and world-class shopping. Includes Burj Khalifa entry and an evening dhow cruise.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Burj Khalifa observation deck',
        'Desert safari with BBQ dinner',
        'Dhow cruise dinner',
        'Dubai Mall visit',
      ],
      categoryIds: ['international', 'weekend'],
    ),
    TourPackageModel(
      id: 'p7', title: 'Swiss Alps', location: 'Switzerland',
      nights: 6, days: 7, rating: 4.9, reviewCount: 980,
      price: 89999, premiumPrice: 112999, originalPrice: 105999,
      description:
          'Snow-capped peaks, glacier trains and lakeside towns. Experience Interlaken, Lucerne and Zermatt in comfort.',
      includesFlights: true, includesHotels: true, includesTransfers: true,
      highlights: [
        'Jungfraujoch excursion',
        'Lake Lucerne cruise',
        'Glacier Express ride',
        'Zermatt village stay',
      ],
      categoryIds: ['international', 'honeymoon'],
    ),
  ];

  late final List<TourBookingModel> _bookings;
  final Set<String> _wishlistIds = {};
  int _counter = 1000;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  TourPackageModel _byId(String id) => _packages.firstWhere((p) => p.id == id,
      orElse: () => throw const TourFailure('Package not found.'));

  @override
  Future<List<TourCategoryModel>> fetchCategories() async {
    await _latency();
    return _categories;
  }

  @override
  Future<List<TourDestinationModel>> fetchDestinations() async {
    await _latency();
    return _destinations;
  }

  @override
  Future<List<TourPackageModel>> fetchPackages(TourSearchParams p) async {
    await _latency();
    final q = p.query.trim().toLowerCase();
    return _packages.where((pkg) {
      final inCat = p.categoryId == null || pkg.categoryIds.contains(p.categoryId);
      final matches = q.isEmpty ||
          pkg.title.toLowerCase().contains(q) ||
          pkg.location.toLowerCase().contains(q);
      return inCat && matches;
    }).toList();
  }

  @override
  Future<TourPackageModel> fetchPackage(String packageId) async {
    await _latency();
    return _byId(packageId);
  }

  @override
  Future<List<TourAddOnModel>> fetchAddOns() async {
    await _latency();
    return _addOns;
  }

  @override
  Future<List<TourPackageModel>> fetchWishlist() async {
    await _latency();
    return _packages.where((p) => _wishlistIds.contains(p.id)).toList();
  }

  @override
  Future<List<TourPackageModel>> toggleWishlist(String packageId) async {
    _wishlistIds.contains(packageId)
        ? _wishlistIds.remove(packageId)
        : _wishlistIds.add(packageId);
    return _packages.where((p) => _wishlistIds.contains(p.id)).toList();
  }

  @override
  Future<TourBookingModel> createBooking(TourCreateBookingParams p) async {
    await _latency();
    final pkg = _byId(p.packageId);
    final selected = _addOns.where((a) => p.addOnIds.contains(a.id));
    final id = 'b${_counter}';
    final reference =
        'TC${DateFormat('yyyyMMdd').format(DateTime.now())}${_counter++}';
    final booking = TourBookingModel(
      id: id,
      reference: reference,
      package: pkg,
      travelDate: p.travelDate,
      travellers: p.travellers,
      packageType: p.packageType,
      addOnIds: p.addOnIds,
      totalAmount: TourPricing.total(
        package: pkg,
        type: p.packageType,
        travellers: p.travellers,
        addOns: selected,
      ),
      status: TourBookingStatus.confirmed,
      customerName: p.customerName.trim(),
      email: p.email.trim(),
      phone: p.phone,
      notes: p.notes.trim(),
      paymentMethod: p.paymentMethod,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<List<TourBookingModel>> fetchBookings() async {
    await _latency();
    return [..._bookings]..sort((a, b) => a.travelDate.compareTo(b.travelDate));
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _latency();
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i != -1) {
      _bookings[i] = _bookings[i].copyWith(status: TourBookingStatus.cancelled);
    }
  }
}
