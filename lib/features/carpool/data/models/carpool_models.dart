import 'dart:convert';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../domain/entities/carpool_entities.dart';

class CarpoolUserModel extends CarpoolUserEntity {
  const CarpoolUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.rating,
    required super.isPremium,
  });

  factory CarpoolUserModel.fromJson(Map<String, dynamic> json) =>
      CarpoolUserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        rating: (json['rating'] as num).toDouble(),
        isPremium: json['isPremium'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'rating': rating,
        'isPremium': isPremium,
      };
}

class CarpoolPopularRouteModel extends CarpoolPopularRouteEntity {
  const CarpoolPopularRouteModel({
    required super.from,
    required super.to,
    required super.price,
    super.fromLat,
    super.fromLng,
    super.toLat,
    super.toLng,
  });

  factory CarpoolPopularRouteModel.fromJson(Map<String, dynamic> json) =>
      CarpoolPopularRouteModel(
        from: json['from'] as String,
        to: json['to'] as String,
        price: json['price'] as int,
        fromLat: (json['fromLat'] as num?)?.toDouble(),
        fromLng: (json['fromLng'] as num?)?.toDouble(),
        toLat: (json['toLat'] as num?)?.toDouble(),
        toLng: (json['toLng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'price': price,
        if (fromLat != null) 'fromLat': fromLat,
        if (fromLng != null) 'fromLng': fromLng,
        if (toLat != null) 'toLat': toLat,
        if (toLng != null) 'toLng': toLng,
      };
}

class CarpoolRideModel extends CarpoolRideEntity {
  const CarpoolRideModel({
    required super.id,
    required super.driverName,
    required super.driverRating,
    required super.driverTrips,
    required super.vehicle,
    required super.from,
    required super.to,
    required super.departure,
    required super.seats,
    required super.pricePerSeat,
    required super.distanceKm,
    required super.status,
    required super.rideType,
    super.totalBookings = 0,
    super.vehicleModel,
    super.vehicleNumber,
    super.originCity,
    super.destinationCity,
    super.rideCode,
    super.driverPhone,
    super.notes,
    super.durationText,
    super.totalDistance,
    super.hasToll,
    super.tollType,
    super.tollRoute,
    super.stopovers,
  });

  /// Extracts place name, city name, and full address from various formats:
  /// - JSON map: {"address": "...", "city": "..."}
  /// - Dart map toString(): {address: Connaught Place, New Delhi, lat: 28.6315, city: Delhi}
  /// - Plain string: "Connaught Place, New Delhi"
  static ({String place, String city, String full}) _parseLocationInfo(
    dynamic loc, [
    dynamic fallbackCity,
  ]) {
    String city = fallbackCity?.toString().trim() ?? '';
    String addr = '';

    if (loc == null) {
      addr = city;
    } else if (loc is Map) {
      final m = loc;
      addr = (m['address'] ??
              m['name'] ??
              m['place'] ??
              m['description'] ??
              m['formattedAddress'] ??
              m['title'])
          ?.toString()
          .trim() ??
          '';
      final mapCity = (m['city'] ??
              m['cityName'] ??
              m['district'] ??
              m['state'])
          ?.toString()
          .trim() ??
          '';
      if (mapCity.isNotEmpty) {
        city = mapCity;
      }
      if (addr.isEmpty) {
        addr = city;
      }
    } else {
      String raw = loc.toString().trim();
      if (raw.startsWith('{') || raw.contains('address:') || raw.contains('lat:')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return _parseLocationInfo(decoded, fallbackCity);
          }
        } catch (_) {}

        // Match Dart Map string: {address: Connaught Place, New Delhi, lat: ...}
        final cityMatch = RegExp(
          r'(?:city|district)\s*[:=]\s*([^,}]+)',
          caseSensitive: false,
        ).firstMatch(raw);

        if (cityMatch != null) {
          final parsedCity = cityMatch.group(1)?.trim().replaceAll(RegExp(r'''[{}"]'''), '') ?? '';
          if (parsedCity.isNotEmpty) {
            city = parsedCity;
          }
        }

        // Clean out metadata keys like lat, lng, latitude, longitude, city, district
        String cleaned = raw
            .replaceAll(RegExp(r',?\s*(?:lat|lng|latitude|longitude)\s*[:=][^,}]+', caseSensitive: false), '')
            .replaceAll(RegExp(r',?\s*(?:city|district|state|country|zip|pin|postalCode|type)\s*[:=][^,}]+', caseSensitive: false), '')
            .replaceAll(RegExp(r'^\s*\{\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*\}\s*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'^(?:address|place|name)\s*[:=]\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'''[{}"]'''), '')
            .trim();

        if (cleaned.endsWith(',')) {
          cleaned = cleaned.substring(0, cleaned.length - 1).trim();
        }

        addr = cleaned.isNotEmpty ? cleaned : city;
      } else {
        addr = raw;
      }
    }

    addr = addr.replaceAll(RegExp(r'''[{}"]'''), '').trim();
    if (addr.endsWith(',')) {
      addr = addr.substring(0, addr.length - 1).trim();
    }

    String place = addr;
    if (addr.contains(',')) {
      final parts = addr.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        place = parts.first;
        if (city.isEmpty && parts.length > 1) {
          city = parts.last;
        }
      }
    }

    if (city.isEmpty) {
      city = place;
    }

    return (place: place, city: city, full: addr);
  }

  factory CarpoolRideModel.fromJson(Map<String, dynamic> json) {
    // 1. Driver info
    String driverName = 'Driver';
    double driverRating = 4.8;
    int driverTrips = 10;
    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverName = d['name']?.toString() ?? driverName;
      driverRating = (d['rating'] as num?)?.toDouble() ?? driverRating;
      driverTrips = (d['totalTrips'] as num?)?.toInt() ??
          (d['trips'] as num?)?.toInt() ??
          driverTrips;
    } else if (json['publisher'] is Map<String, dynamic>) {
      final p = json['publisher'] as Map<String, dynamic>;
      driverName = p['name']?.toString() ?? driverName;
      driverRating = (p['rating'] as num?)?.toDouble() ?? driverRating;
      driverTrips = (p['totalTrips'] as num?)?.toInt() ??
          (p['trips'] as num?)?.toInt() ??
          driverTrips;
    } else {
      driverName = json['driverName']?.toString() ??
          json['driver']?.toString() ??
          driverName;
      driverRating =
          (json['driverRating'] as num?)?.toDouble() ?? driverRating;
      driverTrips = (json['driverTrips'] as num?)?.toInt() ?? driverTrips;
    }

    // 2. Locations (extracts clean place name, city name, and full address)
    final originParsed = _parseLocationInfo(
      json['from'] ?? json['origin'],
      json['originCity'],
    );
    final destParsed = _parseLocationInfo(
      json['to'] ?? json['destination'],
      json['destinationCity'],
    );

    final from = originParsed.place.isNotEmpty
        ? originParsed.place
        : (json['originCity']?.toString() ?? 'Origin');
    final to = destParsed.place.isNotEmpty
        ? destParsed.place
        : (json['destinationCity']?.toString() ?? 'Destination');
    final originCity = originParsed.city.isNotEmpty ? originParsed.city : null;
    final destinationCity = destParsed.city.isNotEmpty ? destParsed.city : null;

    // 3. Departure
    DateTime departure = DateTime.now();
    final depRaw = json['departure'] ?? json['departureTime'] ?? json['date'];
    if (depRaw != null) {
      final parsed = DateTime.tryParse(depRaw.toString());
      if (parsed != null) {
        departure = parsed.toLocal();
      }
    }

    // 4. Seats & Price & Bookings
    final seats = (json['seats'] as num?)?.toInt() ??
        (json['availableSeats'] as num?)?.toInt() ??
        1;
    final pricePerSeat = (json['pricePerSeat'] as num?)?.toInt() ??
        (json['price'] as num?)?.toInt() ??
        100;
    final oLat = (json['originLat'] as num?)?.toDouble() ??
        (json['originCoordinates']?['lat'] as num?)?.toDouble();
    final oLng = (json['originLng'] as num?)?.toDouble() ??
        (json['originCoordinates']?['lng'] as num?)?.toDouble();
    final dLat = (json['destinationLat'] as num?)?.toDouble() ??
        (json['destinationCoordinates']?['lat'] as num?)?.toDouble();
    final dLng = (json['destinationLng'] as num?)?.toDouble() ??
        (json['destinationCoordinates']?['lng'] as num?)?.toDouble();

    final totalDist = (json['totalDistance'] as num?)?.toDouble() ??
        (json['distanceKm'] as num?)?.toDouble() ??
        (json['toll_route'] is Map
            ? (json['toll_route']['distance'] as num?)?.toDouble()
            : null);

    final distanceKm = (json['distanceKm'] as num?)?.toInt() ??
        (totalDist?.toInt()) ??
        (json['distance'] as num?)?.toInt() ??
        CarpoolDistanceCalculator.calculateDistanceKm(
          from,
          to,
          fromLat: oLat,
          fromLng: oLng,
          toLat: dLat,
          toLng: dLng,
        );
    final totalBookings = (json['totalBookings'] as num?)?.toInt() ?? 0;

    // 5. Vehicle
    final vehicleModel = json['vehicleModel']?.toString();
    final vehicleNumber = json['vehicleNumber']?.toString();
    final vehicle = json['vehicle']?.toString() ??
        (vehicleModel != null && vehicleModel.isNotEmpty
            ? (vehicleNumber != null && vehicleNumber.isNotEmpty
                ? '$vehicleModel • $vehicleNumber'
                : vehicleModel)
            : 'Honda City');

    // 6. Status
    CarpoolRideStatus status = CarpoolRideStatus.upcoming;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr != null) {
      if (statusStr == 'completed') {
        status = CarpoolRideStatus.completed;
      } else if (statusStr == 'cancelled' || statusStr == 'canceled') {
        status = CarpoolRideStatus.cancelled;
      } else {
        status = CarpoolRideStatus.upcoming;
      }
    }

    // 7. RideType
    CarpoolRideType rideType = CarpoolRideType.normal;
    final rideTypeStr = json['rideType']?.toString().toLowerCase();
    if (rideTypeStr != null && rideTypeStr == 'premium') {
      rideType = CarpoolRideType.premium;
    }

    final rideCode = json['rideCode']?.toString();
    final driverPhone = (json['publisher'] is Map ? json['publisher']['phone'] : null)?.toString() ??
        json['driverPhone']?.toString() ??
        json['phone']?.toString();
    final notes = json['notes']?.toString();

    // 8. Toll Route, Duration & Stopovers
    Map<String, dynamic>? tollRoute;
    String? durationText;
    if (json['toll_route'] is Map) {
      tollRoute = (json['toll_route'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
      durationText = tollRoute['duration']?.toString();
    } else if (json['tollRoute'] is Map) {
      tollRoute = (json['tollRoute'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
      durationText = tollRoute['duration']?.toString();
    } else if (json['duration'] != null) {
      durationText = json['duration'].toString();
    }

    final hasToll = json['hasToll'] is bool
        ? json['hasToll'] as bool
        : (json['toll_type']?.toString().toLowerCase() == 'toll');

    final tollType = json['toll_type']?.toString() ??
        tollRoute?['type']?.toString();

    List<Map<String, dynamic>>? stopoversList;
    final rawStops =
        json['stopover'] ?? json['stops'] ?? json['stopovers'];
    if (rawStops is List) {
      stopoversList = [];
      for (final s in rawStops) {
        if (s is Map<String, dynamic>) {
          stopoversList.add(s);
        } else if (s is Map) {
          stopoversList.add(s.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
    }

    return CarpoolRideModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          'ride-${DateTime.now().millisecondsSinceEpoch}',
      driverName: driverName,
      driverRating: driverRating,
      driverTrips: driverTrips,
      vehicle: vehicle,
      from: from,
      to: to,
      departure: departure,
      seats: seats,
      pricePerSeat: pricePerSeat,
      distanceKm: distanceKm,
      status: status,
      rideType: rideType,
      totalBookings: totalBookings,
      vehicleModel: vehicleModel,
      vehicleNumber: vehicleNumber,
      originCity: originCity,
      destinationCity: destinationCity,
      rideCode: rideCode,
      driverPhone: driverPhone,
      notes: notes,
      durationText: durationText,
      totalDistance: totalDist,
      hasToll: hasToll,
      tollType: tollType,
      tollRoute: tollRoute,
      stopovers: stopoversList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverName': driverName,
        'driverRating': driverRating,
        'driverTrips': driverTrips,
        'vehicle': vehicle,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'seats': seats,
        'pricePerSeat': pricePerSeat,
        'distanceKm': distanceKm,
        'status': status.name,
        'rideType': rideType.name,
        'totalBookings': totalBookings,
        'vehicleModel': vehicleModel,
        'vehicleNumber': vehicleNumber,
        if (originCity != null) 'originCity': originCity,
        if (destinationCity != null) 'destinationCity': destinationCity,
        if (rideCode != null) 'rideCode': rideCode,
        if (driverPhone != null) 'driverPhone': driverPhone,
        if (notes != null) 'notes': notes,
      };

  @override
  CarpoolRideModel copyWith({
    CarpoolRideStatus? status,
    int? seats,
    int? totalBookings,
    String? vehicleModel,
    String? vehicleNumber,
    String? originCity,
    String? destinationCity,
    String? rideCode,
    String? driverPhone,
    String? notes,
    String? durationText,
    double? totalDistance,
    bool? hasToll,
    String? tollType,
    Map<String, dynamic>? tollRoute,
    List<Map<String, dynamic>>? stopovers,
  }) =>
      CarpoolRideModel(
        id: id,
        driverName: driverName,
        driverRating: driverRating,
        driverTrips: driverTrips,
        vehicle: vehicle,
        from: from,
        to: to,
        departure: departure,
        seats: seats ?? this.seats,
        pricePerSeat: pricePerSeat,
        distanceKm: distanceKm,
        status: status ?? this.status,
        rideType: rideType,
        totalBookings: totalBookings ?? this.totalBookings,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        originCity: originCity ?? this.originCity,
        destinationCity: destinationCity ?? this.destinationCity,
        rideCode: rideCode ?? this.rideCode,
        driverPhone: driverPhone ?? this.driverPhone,
        notes: notes ?? this.notes,
        durationText: durationText ?? this.durationText,
        totalDistance: totalDistance ?? this.totalDistance,
        hasToll: hasToll ?? this.hasToll,
        tollType: tollType ?? this.tollType,
        tollRoute: tollRoute ?? this.tollRoute,
        stopovers: stopovers ?? this.stopovers,
      );
}

class CarpoolTransactionModel extends CarpoolTransactionEntity {
  const CarpoolTransactionModel({
    required super.id,
    required super.title,
    required super.date,
    required super.amount,
    required super.type,
  });

  factory CarpoolTransactionModel.fromJson(Map<String, dynamic> json) =>
      CarpoolTransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        type: CarpoolTransactionType.values.byName(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type.name,
      };
}

class CarpoolWalletModel extends CarpoolWalletEntity {
  const CarpoolWalletModel(
      {required super.balance, required super.transactions});

  factory CarpoolWalletModel.fromJson(Map<String, dynamic> json) =>
      CarpoolWalletModel(
        balance: (json['balance'] as num).toDouble(),
        transactions: (json['transactions'] as List)
            .map((e) =>
                CarpoolTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CarpoolMessageModel extends CarpoolMessageEntity {
  const CarpoolMessageModel({
    required super.id,
    required super.senderName,
    required super.preview,
    required super.timeAgo,
    required super.unreadCount,
    required super.category,
  });

  factory CarpoolMessageModel.fromJson(Map<String, dynamic> json) =>
      CarpoolMessageModel(
        id: json['id'] as String,
        senderName: json['senderName'] as String,
        preview: json['preview'] as String,
        timeAgo: json['timeAgo'] as String,
        unreadCount: json['unreadCount'] as int,
        category:
            CarpoolMessageCategory.values.byName(json['category'] as String),
      );
}
