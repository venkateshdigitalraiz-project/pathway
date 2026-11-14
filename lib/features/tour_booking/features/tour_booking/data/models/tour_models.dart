import '../../domain/entities/tour_entities.dart';

class TourCategoryModel extends TourCategoryEntity {
  const TourCategoryModel({required super.id, required super.name});

  factory TourCategoryModel.fromJson(Map<String, dynamic> json) =>
      TourCategoryModel(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TourDestinationModel extends TourDestinationEntity {
  const TourDestinationModel({
    required super.id,
    required super.name,
    required super.fromPrice,
    required super.packageId,
    super.imageUrl,
  });

  factory TourDestinationModel.fromJson(Map<String, dynamic> json) =>
      TourDestinationModel(
        id: json['id'] as String,
        name: json['name'] as String,
        fromPrice: json['fromPrice'] as int,
        packageId: json['packageId'] as String,
        imageUrl: (json['imageUrl'] as String?) ?? '',
      );
}

class TourAddOnModel extends TourAddOnEntity {
  const TourAddOnModel({
    required super.id,
    required super.name,
    required super.price,
    required super.perPerson,
  });

  factory TourAddOnModel.fromJson(Map<String, dynamic> json) => TourAddOnModel(
        id: json['id'] as String,
        name: json['name'] as String,
        price: json['price'] as int,
        perPerson: json['perPerson'] as bool,
      );
}

class TourPackageModel extends TourPackageEntity {
  const TourPackageModel({
    required super.id,
    required super.title,
    required super.location,
    required super.nights,
    required super.days,
    required super.rating,
    required super.reviewCount,
    required super.price,
    required super.premiumPrice,
    required super.originalPrice,
    required super.description,
    required super.includesFlights,
    required super.includesHotels,
    required super.includesTransfers,
    required super.highlights,
    required super.categoryIds,
    super.imageUrls,
    super.imageCount,
  });

  factory TourPackageModel.fromJson(Map<String, dynamic> json) =>
      TourPackageModel(
        id: json['id'] as String,
        title: json['title'] as String,
        location: json['location'] as String,
        nights: json['nights'] as int,
        days: json['days'] as int,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        price: json['price'] as int,
        premiumPrice: json['premiumPrice'] as int,
        originalPrice: json['originalPrice'] as int,
        description: json['description'] as String,
        includesFlights: json['includesFlights'] as bool,
        includesHotels: json['includesHotels'] as bool,
        includesTransfers: json['includesTransfers'] as bool,
        highlights: List<String>.from(json['highlights'] as List),
        categoryIds: List<String>.from(json['categoryIds'] as List),
        imageUrls: List<String>.from((json['imageUrls'] as List?) ?? const []),
        imageCount: (json['imageCount'] as int?) ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'nights': nights,
        'days': days,
        'rating': rating,
        'reviewCount': reviewCount,
        'price': price,
        'premiumPrice': premiumPrice,
        'originalPrice': originalPrice,
        'description': description,
        'includesFlights': includesFlights,
        'includesHotels': includesHotels,
        'includesTransfers': includesTransfers,
        'highlights': highlights,
        'categoryIds': categoryIds,
        'imageUrls': imageUrls,
        'imageCount': imageCount,
      };
}

class TourBookingModel extends TourBookingEntity {
  const TourBookingModel({
    required super.id,
    required super.reference,
    required super.package,
    required super.travelDate,
    required super.travellers,
    required super.packageType,
    required super.addOnIds,
    required super.totalAmount,
    required super.status,
    required super.customerName,
    required super.email,
    required super.phone,
    required super.notes,
    required super.paymentMethod,
  });

  factory TourBookingModel.fromJson(Map<String, dynamic> json) =>
      TourBookingModel(
        id: json['id'] as String,
        reference: json['reference'] as String,
        package:
            TourPackageModel.fromJson(json['package'] as Map<String, dynamic>),
        travelDate: DateTime.parse(json['travelDate'] as String),
        travellers: json['travellers'] as int,
        packageType:
            TourPackageType.values.byName(json['packageType'] as String),
        addOnIds: List<String>.from(json['addOnIds'] as List),
        totalAmount: json['totalAmount'] as int,
        status: TourBookingStatus.values.byName(json['status'] as String),
        customerName: json['customerName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        notes: (json['notes'] as String?) ?? '',
        paymentMethod:
            TourPaymentMethod.values.byName(json['paymentMethod'] as String),
      );

  @override
  TourBookingModel copyWith({TourBookingStatus? status}) => TourBookingModel(
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
}
