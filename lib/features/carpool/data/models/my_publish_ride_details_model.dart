import '../../domain/entities/carpool_stopover_entity.dart';
import '../../domain/entities/my_publish_ride_details_entity.dart';

String _cleanAddress(dynamic val) {
  if (val == null) return '';
  if (val is Map) {
    return val['address']?.toString() ??
        val['city']?.toString() ??
        val['locality']?.toString() ??
        '';
  }
  final s = val.toString().trim();
  if (s.startsWith('{') && s.contains('address:')) {
    final match = RegExp(r'address:\s*([^,}]+)').firstMatch(s);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
  }
  return s;
}

class MyPublishRidePassengerModel extends MyPublishRidePassengerEntity {
  const MyPublishRidePassengerModel({
    required super.id,
    required super.bookingCode,
    required super.passengerId,
    required super.passengerName,
    required super.passengerPhone,
    super.passengerAvatar,
    required super.seatsBooked,
    required super.totalAmount,
    required super.paymentStatus,
    required super.bookingStatus,
    required super.fromAddress,
    required super.toAddress,
    required super.createdAt,
  });

  factory MyPublishRidePassengerModel.fromJson(Map<String, dynamic> json) {
    final from = _cleanAddress(json['from'] ?? json['pickupPoint']);
    final to = _cleanAddress(json['to'] ?? json['dropoffPoint']);

    String name = 'Passenger';
    String phone = '';
    String? avatar;
    if (json['passenger'] is Map) {
      final p = json['passenger'] as Map;
      name = p['name']?.toString() ??
          p['fullName']?.toString() ??
          name;
      phone = p['phone']?.toString() ??
          p['phoneNumber']?.toString() ??
          phone;
      avatar = p['avatar']?.toString();
    } else if (json['user'] is Map) {
      final u = json['user'] as Map;
      name = u['name']?.toString() ??
          u['fullName']?.toString() ??
          name;
      phone = u['phone']?.toString() ??
          u['phoneNumber']?.toString() ??
          phone;
      avatar = u['avatar']?.toString();
    } else {
      name = json['passengerName']?.toString() ??
          json['userName']?.toString() ??
          name;
      phone = json['passengerPhone']?.toString() ??
          json['phone']?.toString() ??
          phone;
      avatar = json['passengerAvatar']?.toString() ?? json['avatar']?.toString();
    }

    DateTime created = DateTime.now();
    final rawCreated = json['createdAt'] ?? json['timestamp'] ?? json['date'];
    if (rawCreated != null) {
      final parsed = DateTime.tryParse(rawCreated.toString());
      if (parsed != null) created = parsed;
    }

    return MyPublishRidePassengerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      bookingCode: json['bookingCode']?.toString() ??
          'BK-${json['id']?.toString().substring(0, 4) ?? "0000"}',
      passengerId: json['passengerId']?.toString() ??
          (json['passenger'] is Map ? json['passenger']['id']?.toString() : null) ??
          '',
      passengerName: name,
      passengerPhone: phone,
      passengerAvatar: avatar,
      seatsBooked: (json['seatsBooked'] as num?)?.toInt() ??
          (json['seats'] as num?)?.toInt() ??
          1,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ??
          (json['amount'] as num?)?.toInt() ??
          0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'paid',
      bookingStatus: json['bookingStatus']?.toString() ??
          json['status']?.toString() ??
          'confirmed',
      fromAddress: from,
      toAddress: to,
      createdAt: created,
    );
  }
}

class MyPublishRideDetailsModel extends MyPublishRideDetailsEntity {
  const MyPublishRideDetailsModel({
    required super.id,
    required super.rideCode,
    required super.publisherId,
    required super.publisherName,
    required super.publisherPhone,
    super.publisherAvatar,
    required super.originAddress,
    required super.originCity,
    super.originLat,
    super.originLng,
    required super.destinationAddress,
    required super.destinationCity,
    super.destinationLat,
    super.destinationLng,
    required super.departureTime,
    required super.availableSeats,
    required super.totalSeats,
    required super.totalSeatsOccupied,
    required super.totalPassengers,
    required super.pricePerSeat,
    required super.vehicleModel,
    required super.vehicleNumber,
    required super.notes,
    required super.status,
    super.createdAt,
    super.bookings,
    super.stopovers,
    super.totalDistance,
    super.hasToll,
    super.tollType,
  });

  factory MyPublishRideDetailsModel.fromJson(Map<String, dynamic> raw) {
    Map<String, dynamic> json = raw;
    Map<String, dynamic>? rootData;

    if (raw['data'] is Map<String, dynamic>) {
      rootData = raw['data'] as Map<String, dynamic>;
      if (rootData['ride'] is Map<String, dynamic>) {
        json = rootData['ride'] as Map<String, dynamic>;
      } else {
        json = rootData;
      }
    } else if (raw['ride'] is Map<String, dynamic>) {
      json = raw['ride'] as Map<String, dynamic>;
    }

    // Origin parsing
    String originAddr = '';
    String originCity = '';
    double? originLat;
    double? originLng;

    if (json['origin'] is Map) {
      final o = json['origin'] as Map;
      originAddr = o['address']?.toString() ?? o['city']?.toString() ?? '';
      originCity = o['city']?.toString() ??
          json['originCity']?.toString() ??
          originAddr;
      originLat = (o['lat'] as num?)?.toDouble();
      originLng = (o['lng'] as num?)?.toDouble();
    } else if (json['origin'] != null) {
      originAddr = json['origin'].toString();
      originCity = json['originCity']?.toString() ?? originAddr;
    } else if (json['from'] != null) {
      originAddr = json['from'].toString();
      originCity = json['originCity']?.toString() ?? originAddr;
    }

    // Destination parsing
    String destAddr = '';
    String destCity = '';
    double? destLat;
    double? destLng;

    if (json['destination'] is Map) {
      final d = json['destination'] as Map;
      destAddr = d['address']?.toString() ?? d['city']?.toString() ?? '';
      destCity = d['city']?.toString() ??
          json['destinationCity']?.toString() ??
          destAddr;
      destLat = (d['lat'] as num?)?.toDouble();
      destLng = (d['lng'] as num?)?.toDouble();
    } else if (json['destination'] != null) {
      destAddr = json['destination'].toString();
      destCity = json['destinationCity']?.toString() ?? destAddr;
    } else if (json['to'] != null) {
      destAddr = json['to'].toString();
      destCity = json['destinationCity']?.toString() ?? destAddr;
    }

    // Publisher parsing
    String pubId = json['publisherId']?.toString() ?? '';
    String pubName = 'User 3210';
    String pubPhone = '';
    String? pubAvatar;

    if (json['publisher'] is Map) {
      final p = json['publisher'] as Map;
      pubId = p['id']?.toString() ?? pubId;
      pubName = p['name']?.toString() ?? pubName;
      pubPhone = p['phone']?.toString() ?? pubPhone;
      pubAvatar = p['avatar']?.toString();
    } else if (json['driver'] is Map) {
      final d = json['driver'] as Map;
      pubId = d['id']?.toString() ?? pubId;
      pubName = d['name']?.toString() ?? pubName;
      pubPhone = d['phone']?.toString() ?? pubPhone;
    }

    // Departure Time parsing
    DateTime depTime = DateTime.now();
    final rawDep = json['departureTime'] ?? json['departure'];
    if (rawDep != null) {
      final parsed = DateTime.tryParse(rawDep.toString());
      if (parsed != null) depTime = parsed;
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString());
    }

    // Bookings parsing:
    // API returns { "status": "success", "data": { "ride": { ... }, "bookings": [ ... ], "totalPassengers": 3, "totalSeatsOccupied": 5 } }
    final List<MyPublishRidePassengerModel> bookings = [];
    dynamic rawBookings;
    if (rootData?['bookings'] is List && (rootData!['bookings'] as List).isNotEmpty) {
      rawBookings = rootData['bookings'];
    } else if (json['bookings'] is List && (json['bookings'] as List).isNotEmpty) {
      rawBookings = json['bookings'];
    } else if (rootData?['bookings'] is List) {
      rawBookings = rootData!['bookings'];
    } else if (json['bookings'] is List) {
      rawBookings = json['bookings'];
    } else {
      rawBookings = rootData?['passengers'] ??
          json['passengers'] ??
          rootData?['passengerList'] ??
          json['passengerList'];
    }

    if (rawBookings is List) {
      for (final item in rawBookings) {
        if (item is Map<String, dynamic>) {
          bookings.add(MyPublishRidePassengerModel.fromJson(item));
        } else if (item is Map) {
          bookings.add(MyPublishRidePassengerModel.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ));
        }
      }
    }

    final totalSeats = (json['totalSeats'] as num?)?.toInt() ?? 6;
    final availableSeats =
        (json['availableSeats'] as num?)?.toInt() ?? totalSeats;

    // Total seats occupied: Prefer rootData['totalSeatsOccupied'] (e.g. 5)
    int totalOccupied = (rootData?['totalSeatsOccupied'] as num?)?.toInt() ??
        (json['totalSeatsOccupied'] as num?)?.toInt() ??
        (totalSeats - availableSeats).clamp(0, totalSeats);

    // Total passengers: Prefer rootData['totalPassengers'] (e.g. 3)
    int totalPassengers = (rootData?['totalPassengers'] as num?)?.toInt() ??
        (json['totalPassengers'] as num?)?.toInt() ??
        bookings.length;

    // Fallback/reconcile with bookings list if populated
    if (bookings.isNotEmpty) {
      if (totalPassengers == 0) {
        totalPassengers = bookings.length;
      }
      final computedOccupied =
          bookings.fold<int>(0, (sum, b) => sum + b.seatsBooked);
      if (totalOccupied == 0 && computedOccupied > 0) {
        totalOccupied = computedOccupied;
      }
    }

    // Stopovers parsing:
    // API returns "stopover": [ { "order": 1, "city": "Choutuppal", ... } ] or "stops"
    final List<CarpoolStopoverEntity> stopovers = [];
    final rawStopovers =
        json['stopover'] ?? json['stops'] ?? json['stopovers'];
    if (rawStopovers is List) {
      for (int i = 0; i < rawStopovers.length; i++) {
        final item = rawStopovers[i];
        if (item is Map<String, dynamic>) {
          stopovers.add(CarpoolStopoverEntity.fromJson({
            ...item,
            if (!item.containsKey('order') && !item.containsKey('stopOrder'))
              'order': i + 1,
          }));
        } else if (item is Map) {
          final m = item.map((k, v) => MapEntry(k.toString(), v));
          stopovers.add(CarpoolStopoverEntity.fromJson({
            ...m,
            if (!m.containsKey('order') && !m.containsKey('stopOrder'))
              'order': i + 1,
          }));
        }
      }
    }
    stopovers.sort((a, b) => a.order.compareTo(b.order));

    final totalDist = (json['totalDistance'] as num?)?.toDouble() ??
        (json['distanceKm'] as num?)?.toDouble() ??
        (json['toll_route'] is Map
            ? (json['toll_route']['distance'] as num?)?.toDouble()
            : null);

    final hasToll = json['hasToll'] is bool
        ? json['hasToll'] as bool
        : (json['toll_type']?.toString().toLowerCase() == 'toll');

    final tollType = json['toll_type']?.toString() ??
        (json['toll_route'] is Map
            ? json['toll_route']['type']?.toString()
            : null);

    return MyPublishRideDetailsModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rideCode: json['rideCode']?.toString() ?? 'CR-${json['id']?.toString().substring(0, 4) ?? "0000"}',
      publisherId: pubId,
      publisherName: pubName,
      publisherPhone: pubPhone,
      publisherAvatar: pubAvatar,
      originAddress: originAddr,
      originCity: originCity,
      originLat: originLat,
      originLng: originLng,
      destinationAddress: destAddr,
      destinationCity: destCity,
      destinationLat: destLat,
      destinationLng: destLng,
      departureTime: depTime,
      availableSeats: availableSeats,
      totalSeats: totalSeats,
      totalSeatsOccupied: totalOccupied,
      totalPassengers: totalPassengers,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toInt() ?? 0,
      vehicleModel: json['vehicleModel']?.toString() ?? 'Toyota',
      vehicleNumber: json['vehicleNumber']?.toString() ?? 'Verified Car',
      notes: json['notes']?.toString() ?? 'Direct highway drive, air-conditioned.',
      status: json['status']?.toString() ?? 'active',
      createdAt: createdAt,
      bookings: bookings,
      stopovers: stopovers,
      totalDistance: totalDist,
      hasToll: hasToll,
      tollType: tollType,
    );
  }
}
