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

    // Preserve root `ride` map if present before unwrapping `booking`
    Map<String, dynamic>? rootRide;
    if (data['ride'] is Map) {
      rootRide = (data['ride'] as Map).map((k, v) => MapEntry(k.toString(), v));
    }

    // Drill down if payload is wrapped in `booking` or `data`
    if (data.containsKey('booking') && data['booking'] is Map) {
      data = (data['booking'] as Map).map((k, v) => MapEntry(k.toString(), v));
    } else if (data.containsKey('data') && data['data'] is Map) {
      final inner = data['data'] as Map;
      if (inner.containsKey('ride') && inner['ride'] is Map) {
        rootRide ??= (inner['ride'] as Map).map((k, v) => MapEntry(k.toString(), v));
      }
      if (inner.containsKey('booking') && inner['booking'] is Map) {
        data = (inner['booking'] as Map).map((k, v) => MapEntry(k.toString(), v));
      } else {
        data = inner.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    final id = (data['bookingId'] ??
            data['id'] ??
            data['_id'] ??
            data['bookingCode'] ??
            'BK-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final rideId = (data['rideId'] ??
            (data['ride'] is Map
                ? data['ride']['id'] ?? data['ride']['_id']
                : null) ??
            (data['ride'] is String ? data['ride'] : null) ??
            'RD-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final passengerId = (data['passengerId'] ??
            data['userId'] ??
            (data['passenger'] is Map
                ? data['passenger']['id'] ?? data['passenger']['_id']
                : null) ??
            (data['passenger'] is String ? data['passenger'] : null) ??
            (data['user'] is Map
                ? data['user']['id'] ?? data['user']['_id']
                : null) ??
            (data['user'] is String ? data['user'] : null) ??
            'PS-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    String riderName = 'Rider';
    if (data['passenger'] is Map) {
      riderName = data['passenger']['name']?.toString() ??
          data['passenger']['fullName']?.toString() ??
          riderName;
    } else if (data['user'] is Map) {
      riderName = data['user']['fullName']?.toString() ??
          data['user']['name']?.toString() ??
          riderName;
    } else if (data['riderName'] != null &&
        data['riderName'].toString().isNotEmpty) {
      riderName = data['riderName'].toString();
    } else if (data['passengerName'] != null &&
        data['passengerName'].toString().isNotEmpty) {
      riderName = data['passengerName'].toString();
    } else if (data['name'] != null &&
        data['name'] is String &&
        data['name'].toString().isNotEmpty) {
      riderName = data['name'].toString();
    } else if (data['bookingCode'] != null) {
      riderName = 'Rider (${data['bookingCode']})';
    }

    String riderPhone = '+91 9876543210';
    if (data['passenger'] is Map) {
      riderPhone = data['passenger']['phone']?.toString() ?? riderPhone;
    } else if (data['user'] is Map) {
      riderPhone = data['user']['phoneNumber']?.toString() ??
          data['user']['phone']?.toString() ??
          riderPhone;
    } else if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
      riderPhone = data['phone'].toString();
    } else if (data['riderPhone'] != null &&
        data['riderPhone'].toString().isNotEmpty) {
      riderPhone = data['riderPhone'].toString();
    }

    final rating = (data['rating'] != null)
        ? (double.tryParse(data['rating'].toString()) ?? 4.8)
        : (data['passenger'] is Map && data['passenger']['rating'] != null
            ? (double.tryParse(data['passenger']['rating'].toString()) ?? 4.8)
            : 4.8);

    final totalRides = (data['totalRides'] != null)
        ? (int.tryParse(data['totalRides'].toString()) ?? 24)
        : (data['passenger'] is Map && data['passenger']['rides'] != null
            ? (int.tryParse(data['passenger']['rides'].toString()) ?? 24)
            : 24);

    String fromAddress = 'Pickup Point';
    if (data['pickupPoint'] != null &&
        data['pickupPoint'].toString().isNotEmpty) {
      fromAddress = data['pickupPoint'].toString();
    } else if (data['pickupLocation'] != null &&
        data['pickupLocation'].toString().isNotEmpty) {
      fromAddress = data['pickupLocation'].toString();
    } else if (data['from'] is Map) {
      fromAddress = data['from']['address']?.toString() ??
          data['from']['city']?.toString() ??
          data['from']['locality']?.toString() ??
          fromAddress;
    } else if (data['from'] != null && data['from'].toString().isNotEmpty) {
      fromAddress = data['from'].toString();
    } else if (data['origin'] is Map) {
      fromAddress = data['origin']['address']?.toString() ??
          data['origin']['city']?.toString() ??
          fromAddress;
    } else if (data['origin'] != null && data['origin'].toString().isNotEmpty) {
      fromAddress = data['origin'].toString();
    } else if (data['fromAddress'] != null &&
        data['fromAddress'].toString().isNotEmpty) {
      fromAddress = data['fromAddress'].toString();
    }

    String toAddress = 'Drop-off Point';
    if (data['dropoffPoint'] != null &&
        data['dropoffPoint'].toString().isNotEmpty) {
      toAddress = data['dropoffPoint'].toString();
    } else if (data['dropoffLocation'] != null &&
        data['dropoffLocation'].toString().isNotEmpty) {
      toAddress = data['dropoffLocation'].toString();
    } else if (data['to'] is Map) {
      toAddress = data['to']['address']?.toString() ??
          data['to']['city']?.toString() ??
          data['to']['locality']?.toString() ??
          toAddress;
    } else if (data['to'] != null && data['to'].toString().isNotEmpty) {
      toAddress = data['to'].toString();
    } else if (data['destination'] is Map) {
      toAddress = data['destination']['address']?.toString() ??
          data['destination']['city']?.toString() ??
          toAddress;
    } else if (data['destination'] != null &&
        data['destination'].toString().isNotEmpty) {
      toAddress = data['destination'].toString();
    } else if (data['toAddress'] != null &&
        data['toAddress'].toString().isNotEmpty) {
      toAddress = data['toAddress'].toString();
    }

    final seatsBooked = int.tryParse(
          data['seatsBooked']?.toString() ??
              data['seats']?.toString() ??
              data['bookedSeats']?.toString() ??
              '1',
        ) ??
        1;

    final totalAmount = int.tryParse(
          data['totalAmount']?.toString() ??
              data['amount']?.toString() ??
              data['fare']?.toString() ??
              data['price']?.toString() ??
              '550',
        ) ??
        550;

    DateTime createdAt = DateTime.now();
    final rawDate = data['createdAt'] ?? data['timestamp'] ?? data['date'];
    if (rawDate != null) {
      createdAt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    final distanceKm = double.tryParse(
            data['distance']?.toString() ??
                data['distanceKm']?.toString() ??
                '2.8') ??
        2.8;

    final etaMin = int.tryParse(data['eta']?.toString() ??
            data['etaMin']?.toString() ??
            '6') ??
        6;

    String? vehicleModel;
    if (data['ride'] is Map) {
      vehicleModel = data['ride']['vehicleModel']?.toString();
    }
    vehicleModel ??= rootRide?['vehicleModel']?.toString();
    vehicleModel ??= data['vehicleModel']?.toString() ?? 'Sedan';

    String? vehicleNumber;
    if (data['ride'] is Map) {
      vehicleNumber = data['ride']['vehicleNumber']?.toString();
    }
    vehicleNumber ??= rootRide?['vehicleNumber']?.toString();
    vehicleNumber ??= data['vehicleNumber']?.toString() ?? 'Verified Car';

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
