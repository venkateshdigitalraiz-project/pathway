import 'package:equatable/equatable.dart';

/// Entity representing an available rider booking raised by a user via socket `BOOKING_CREATED`.
class AvailableRiderEntity extends Equatable {
  final String bookingId;
  final String rideId;
  final String passengerId;
  final String riderName;
  final String riderPhone;
  final double rating;
  final int totalRides;
  final String fromAddress;
  final String toAddress;
  final int seatsBooked;
  final int totalAmount;
  final DateTime createdAt;
  final double distanceKm;
  final int etaMin;
  final String? vehicleModel;
  final String? vehicleNumber;
  final bool isNew;

  const AvailableRiderEntity({
    required this.bookingId,
    required this.rideId,
    required this.passengerId,
    required this.riderName,
    required this.riderPhone,
    required this.rating,
    required this.totalRides,
    required this.fromAddress,
    required this.toAddress,
    required this.seatsBooked,
    required this.totalAmount,
    required this.createdAt,
    this.distanceKm = 2.8,
    this.etaMin = 6,
    this.vehicleModel,
    this.vehicleNumber,
    this.isNew = false,
  });

  /// Factory parser for backend Socket.IO `BOOKING_CREATED` payloads
  factory AvailableRiderEntity.fromJson(dynamic rawData) {
    Map<String, dynamic> data;
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = rawData.map((k, v) => MapEntry(k.toString(), v));
    } else {
      data = {};
    }

    // Drill down if payload is wrapped in `booking` or `data`
    if (data.containsKey('booking') && data['booking'] is Map) {
      data = (data['booking'] as Map).map((k, v) => MapEntry(k.toString(), v));
    } else if (data.containsKey('data') && data['data'] is Map) {
      final inner = data['data'] as Map;
      if (inner.containsKey('booking') && inner['booking'] is Map) {
        data = (inner['booking'] as Map).map((k, v) => MapEntry(k.toString(), v));
      } else {
        data = inner.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    final id = (data['id'] ??
            data['bookingId'] ??
            data['_id'] ??
            'BK-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final rideId = (data['rideId'] ??
            data['ride']?['id'] ??
            data['ride']?['_id'] ??
            'RD-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final passengerId = (data['passengerId'] ??
            data['userId'] ??
            data['passenger']?['id'] ??
            'PS-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final riderName = (data['passenger']?['name'] ??
            data['user']?['fullName'] ??
            data['user']?['name'] ??
            data['passengerName'] ??
            data['riderName'] ??
            data['name'] ??
            'Priya Sharma')
        .toString();

    final riderPhone = (data['passenger']?['phone'] ??
            data['user']?['phoneNumber'] ??
            data['phone'] ??
            '+91 9876543210')
        .toString();

    final rating = (data['rating'] != null)
        ? (double.tryParse(data['rating'].toString()) ?? 4.8)
        : (data['passenger']?['rating'] != null
            ? (double.tryParse(data['passenger']['rating'].toString()) ?? 4.8)
            : 4.8);

    final totalRides = (data['totalRides'] != null)
        ? (int.tryParse(data['totalRides'].toString()) ?? 24)
        : (data['passenger']?['rides'] != null
            ? (int.tryParse(data['passenger']['rides'].toString()) ?? 24)
            : 24);

    String fromAddress = 'LB Nagar, Hyderabad';
    if (data['from'] is Map) {
      fromAddress = data['from']['address']?.toString() ??
          data['from']['city']?.toString() ??
          data['from']['locality']?.toString() ??
          fromAddress;
    } else if (data['from'] != null && data['from'].toString().isNotEmpty) {
      fromAddress = data['from'].toString();
    } else if (data['origin'] is Map) {
      fromAddress = data['origin']['address']?.toString() ?? fromAddress;
    }

    String toAddress = 'Miyapur, Hyderabad';
    if (data['to'] is Map) {
      toAddress = data['to']['address']?.toString() ??
          data['to']['city']?.toString() ??
          data['to']['locality']?.toString() ??
          toAddress;
    } else if (data['to'] != null && data['to'].toString().isNotEmpty) {
      toAddress = data['to'].toString();
    } else if (data['destination'] is Map) {
      toAddress = data['destination']['address']?.toString() ?? toAddress;
    }

    final seatsBooked =
        int.tryParse(data['seatsBooked']?.toString() ?? '1') ?? 1;

    final totalAmount =
        int.tryParse(data['totalAmount']?.toString() ?? '543') ?? 543;

    final createdAt = data['createdAt'] != null
        ? (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now();

    final distanceKm = double.tryParse(
            data['distance']?.toString() ??
                data['distanceKm']?.toString() ??
                '2.8') ??
        2.8;

    final etaMin = int.tryParse(data['eta']?.toString() ??
            data['etaMin']?.toString() ??
            '6') ??
        6;

    final vehicleModel = data['ride']?['vehicleModel']?.toString() ??
        data['vehicleModel']?.toString() ??
        'Hgigih';

    final vehicleNumber = data['ride']?['vehicleNumber']?.toString() ??
        data['vehicleNumber']?.toString() ??
        'GVJVHCY';

    return AvailableRiderEntity(
      bookingId: id,
      rideId: rideId,
      passengerId: passengerId,
      riderName: riderName,
      riderPhone: riderPhone,
      rating: rating,
      totalRides: totalRides,
      fromAddress: fromAddress,
      toAddress: toAddress,
      seatsBooked: seatsBooked,
      totalAmount: totalAmount,
      createdAt: createdAt,
      distanceKm: distanceKm,
      etaMin: etaMin,
      vehicleModel: vehicleModel,
      vehicleNumber: vehicleNumber,
      isNew: true,
    );
  }

  AvailableRiderEntity copyWith({
    String? bookingId,
    String? rideId,
    String? passengerId,
    String? riderName,
    String? riderPhone,
    double? rating,
    int? totalRides,
    String? fromAddress,
    String? toAddress,
    int? seatsBooked,
    int? totalAmount,
    DateTime? createdAt,
    double? distanceKm,
    int? etaMin,
    String? vehicleModel,
    String? vehicleNumber,
    bool? isNew,
  }) {
    return AvailableRiderEntity(
      bookingId: bookingId ?? this.bookingId,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMin: etaMin ?? this.etaMin,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        rideId,
        passengerId,
        riderName,
        riderPhone,
        rating,
        totalRides,
        fromAddress,
        toAddress,
        seatsBooked,
        totalAmount,
        createdAt,
        distanceKm,
        etaMin,
        vehicleModel,
        vehicleNumber,
        isNew,
      ];
}
