import 'package:equatable/equatable.dart';

enum TourBookingStatus { confirmed, pending, completed, cancelled }

enum TourPackageType { standard, premium }

enum TourPaymentMethod { upi, card, netBanking, wallet, payLater }

/// Business error shown to the user.
class TourFailure implements Exception {
  const TourFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class TourCategoryEntity extends Equatable {
  const TourCategoryEntity({required this.id, required this.name});
  final String id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}

class TourDestinationEntity extends Equatable {
  const TourDestinationEntity({
    required this.id,
    required this.name,
    required this.fromPrice,
    required this.packageId,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final int fromPrice;
  final String packageId;
  final String imageUrl;

  @override
  List<Object?> get props => [id, name, fromPrice, packageId, imageUrl];
}

class TourAddOnEntity extends Equatable {
  const TourAddOnEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.perPerson,
  });

  final String id;
  final String name;
  final int price;
  final bool perPerson;

  String get priceLabel => perPerson ? 'per Person' : '';

  @override
  List<Object?> get props => [id, name, price, perPerson];
}

class TourPackageEntity extends Equatable {
  const TourPackageEntity({
    required this.id,
    required this.title,
    required this.location,
    required this.nights,
    required this.days,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.premiumPrice,
    required this.originalPrice,
    required this.description,
    required this.includesFlights,
    required this.includesHotels,
    required this.includesTransfers,
    required this.highlights,
    required this.categoryIds,
    this.imageUrls = const [],
    this.imageCount = 10,
  });

  final String id;
  final String title;
  final String location;
  final int nights;
  final int days;
  final double rating;
  final int reviewCount;
  final int price;
  final int premiumPrice;
  final int originalPrice;
  final String description;
  final bool includesFlights;
  final bool includesHotels;
  final bool includesTransfers;
  final List<String> highlights;
  final List<String> categoryIds;
  final List<String> imageUrls;
  final int imageCount;

  String get duration => '$nights Nights / $days Days';
  String get coverImage => imageUrls.isEmpty ? '' : imageUrls.first;

  int get discountPercent => originalPrice <= price
      ? 0
      : (((originalPrice - price) / originalPrice) * 100).round();

  int priceFor(TourPackageType type) =>
      type == TourPackageType.premium ? premiumPrice : price;

  @override
  List<Object?> get props => [
        id, title, location, nights, days, rating, reviewCount, price,
        premiumPrice, originalPrice, description, includesFlights,
        includesHotels, includesTransfers, highlights, categoryIds, imageUrls,
        imageCount,
      ];
}

/// Single source of truth for trip pricing (used by the UI state and data).
class TourPricing {
  TourPricing._();

  static int total({
    required TourPackageEntity package,
    required TourPackageType type,
    required int travellers,
    required Iterable<TourAddOnEntity> addOns,
  }) {
    var sum = package.priceFor(type) * travellers;
    for (final a in addOns) {
      sum += a.perPerson ? a.price * travellers : a.price;
    }
    return sum;
  }
}

class TourBookingEntity extends Equatable {
  const TourBookingEntity({
    required this.id,
    required this.reference,
    required this.package,
    required this.travelDate,
    required this.travellers,
    required this.packageType,
    required this.addOnIds,
    required this.totalAmount,
    required this.status,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.notes,
    required this.paymentMethod,
  });

  final String id;
  final String reference;
  final TourPackageEntity package;
  final DateTime travelDate;
  final int travellers;
  final TourPackageType packageType;
  final List<String> addOnIds;
  final int totalAmount;
  final TourBookingStatus status;
  final String customerName;
  final String email;
  final String phone;
  final String notes;
  final TourPaymentMethod paymentMethod;

  DateTime get endDate => travelDate.add(Duration(days: package.days - 1));

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isCancelled => status == TourBookingStatus.cancelled;

  bool get isUpcoming =>
      !isCancelled &&
      status != TourBookingStatus.completed &&
      !endDate.isBefore(_today);

  bool get isPast =>
      !isCancelled &&
      (status == TourBookingStatus.completed || endDate.isBefore(_today));

  TourBookingEntity copyWith({TourBookingStatus? status}) => TourBookingEntity(
        id: id,
        reference: reference,
        package: package,
        travelDate: travelDate,
        travellers: travellers,
        packageType: packageType,
        addOnIds: addOnIds,
        totalAmount: totalAmount,
        status: status ?? this.status,
        customerName: customerName,
        email: email,
        phone: phone,
        notes: notes,
        paymentMethod: paymentMethod,
      );

  @override
  List<Object?> get props => [
        id, reference, package, travelDate, travellers, packageType, addOnIds,
        totalAmount, status, customerName, email, phone, notes, paymentMethod,
      ];
}

class TourSearchParams extends Equatable {
  const TourSearchParams({this.categoryId, this.query = ''});
  final String? categoryId;
  final String query;
  @override
  List<Object?> get props => [categoryId, query];
}

class TourCreateBookingParams extends Equatable {
  const TourCreateBookingParams({
    required this.packageId,
    required this.travelDate,
    required this.travellers,
    required this.packageType,
    required this.addOnIds,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.notes,
    required this.paymentMethod,
  });

  final String packageId;
  final DateTime travelDate;
  final int travellers;
  final TourPackageType packageType;
  final List<String> addOnIds;
  final String customerName;
  final String email;
  final String phone;
  final String notes;
  final TourPaymentMethod paymentMethod;

  @override
  List<Object?> get props => [
        packageId, travelDate, travellers, packageType, addOnIds, customerName,
        email, phone, notes, paymentMethod,
      ];
}
