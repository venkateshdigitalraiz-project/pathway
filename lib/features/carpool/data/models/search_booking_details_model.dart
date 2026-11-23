import '../../domain/entities/search_booking_details_entity.dart';

class DriverDetailsModel extends DriverDetailsEntity {
  const DriverDetailsModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.rating,
    super.totalTrips = 0,
  });

  factory DriverDetailsModel.fromJson(Map<String, dynamic> json) {
    return DriverDetailsModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Driver',
      phone: json['phone']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ??
          (json['trips'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'rating': rating,
    'totalTrips': totalTrips,
  };
}

class SearchBookingStopoverModel extends SearchBookingStopoverEntity {
  const SearchBookingStopoverModel({
    required super.order,
    required super.city,
    required super.address,
    super.state = '',
    super.latitude = 0.0,
    super.longitude = 0.0,
  });

  factory SearchBookingStopoverModel.fromJson(Map<String, dynamic> json) {
    return SearchBookingStopoverModel(
      order: (json['order'] as num?)?.toInt() ??
          (json['stopOrder'] as num?)?.toInt() ??
          1,
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'order': order,
    'city': city,
    'address': address,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class SearchBookingDetailsModel extends SearchBookingDetailsEntity {
  const SearchBookingDetailsModel({
    required super.id,
    required super.publisherId,
    required super.origin,
    super.originAddress = '',
    super.originCity = '',
    required super.originLat,
    required super.originLng,
    required super.destination,
    super.destinationAddress = '',
    super.destinationCity = '',
    required super.destinationLat,
    required super.destinationLng,
    required super.departureTime,
    required super.availableSeats,
    super.totalSeats = 1,
    required super.pricePerSeat,
    required super.vehicleModel,
    required super.vehicleNumber,
    required super.notes,
    super.status = 'active',
    super.rideCode = '',
    super.totalDistance = 0.0,
    super.distanceKm = 0.0,
    super.hasToll = false,
    super.tollType = 'no_toll',
    super.durationText,
    super.tollRoute,
    super.stopovers = const [],
    required super.driver,
  });

  factory SearchBookingDetailsModel.fromJson(Map<String, dynamic> json) {
    // 1. Driver / Publisher parsing
    DriverDetailsEntity driver;
    if (json['publisher'] is Map<String, dynamic>) {
      driver = DriverDetailsModel.fromJson(
        json['publisher'] as Map<String, dynamic>,
      );
    } else if (json['publisher'] is Map) {
      driver = DriverDetailsModel.fromJson(
        (json['publisher'] as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
    } else if (json['driver'] is Map<String, dynamic>) {
      driver = DriverDetailsModel.fromJson(
        json['driver'] as Map<String, dynamic>,
      );
    } else if (json['driver'] is Map) {
      driver = DriverDetailsModel.fromJson(
        (json['driver'] as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
    } else {
      driver = DriverDetailsEntity(
        id: json['publisherId']?.toString() ?? '',
        name: json['driverName']?.toString() ?? 'Driver',
        phone: json['phone']?.toString() ?? '',
        rating: (json['driverRating'] as num?)?.toDouble() ?? 4.8,
        totalTrips: (json['driverTrips'] as num?)?.toInt() ?? 0,
      );
    }

    // 2. Origin parsing (supports Map or String)
    String origin = '';
    String originAddress = '';
    String originCity = json['originCity']?.toString() ?? '';
    double originLat = (json['originLat'] as num?)?.toDouble() ?? 0.0;
    double originLng = (json['originLng'] as num?)?.toDouble() ?? 0.0;

    final origRaw = json['origin'] ?? json['from'];
    if (origRaw is Map) {
      originAddress = origRaw['address']?.toString() ?? '';
      originCity = originCity.isNotEmpty
          ? originCity
          : (origRaw['city']?.toString() ?? '');
      originLat = (origRaw['lat'] as num?)?.toDouble() ??
          (origRaw['latitude'] as num?)?.toDouble() ??
          originLat;
      originLng = (origRaw['lng'] as num?)?.toDouble() ??
          (origRaw['longitude'] as num?)?.toDouble() ??
          originLng;
      origin = originAddress.isNotEmpty ? originAddress : originCity;
    } else if (origRaw != null) {
      origin = origRaw.toString();
      originAddress = origin;
    }

    // 3. Destination parsing (supports Map or String)
    String destination = '';
    String destinationAddress = '';
    String destinationCity = json['destinationCity']?.toString() ??
        json['city']?.toString() ??
        '';
    double destinationLat = (json['destinationLat'] as num?)?.toDouble() ?? 0.0;
    double destinationLng = (json['destinationLng'] as num?)?.toDouble() ?? 0.0;

    final destRaw = json['destination'] ?? json['to'];
    if (destRaw is Map) {
      destinationAddress = destRaw['address']?.toString() ?? '';
      destinationCity = destinationCity.isNotEmpty
          ? destinationCity
          : (destRaw['city']?.toString() ?? '');
      destinationLat = (destRaw['lat'] as num?)?.toDouble() ??
          (destRaw['latitude'] as num?)?.toDouble() ??
          destinationLat;
      destinationLng = (destRaw['lng'] as num?)?.toDouble() ??
          (destRaw['longitude'] as num?)?.toDouble() ??
          destinationLng;
      destination = destinationAddress.isNotEmpty
          ? destinationAddress
          : destinationCity;
    } else if (destRaw != null) {
      destination = destRaw.toString();
      destinationAddress = destination;
    }

    // 4. Departure time
    DateTime depTime = DateTime.now();
    final rawDeparture = json['departureTime'] ??
        json['departure'] ??
        json['date'];
    if (rawDeparture != null) {
      final parsed = DateTime.tryParse(rawDeparture.toString());
      if (parsed != null) depTime = parsed.toLocal();
    }

    // 5. Seats & Price
    final availableSeats = (json['availableSeats'] as num?)?.toInt() ??
        (json['seats'] as num?)?.toInt() ??
        1;
    final totalSeats = (json['totalSeats'] as num?)?.toInt() ??
        availableSeats;
    final pricePerSeat = (json['pricePerSeat'] as num?)?.toInt() ??
        (json['price'] as num?)?.toInt() ??
        0;

    // 6. Toll Route & Distance
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

    final totalDist = (json['totalDistance'] as num?)?.toDouble() ??
        (json['distanceKm'] as num?)?.toDouble() ??
        (tollRoute?['distance'] as num?)?.toDouble() ??
        0.0;
    final distKm = (json['distanceKm'] as num?)?.toDouble() ?? totalDist;

    final hasToll = json['hasToll'] is bool
        ? json['hasToll'] as bool
        : (json['toll_type']?.toString().toLowerCase() == 'toll');
    final tollType = json['toll_type']?.toString() ??
        tollRoute?['type']?.toString() ??
        'no_toll';

    // 7. Stopovers / Via stops
    final List<SearchBookingStopoverEntity> stopoversList = [];
    final rawStops = json['stopover'] ?? json['stops'] ?? json['stopovers'];
    if (rawStops is List) {
      for (final s in rawStops) {
        if (s is Map<String, dynamic>) {
          stopoversList.add(SearchBookingStopoverModel.fromJson(s));
        } else if (s is Map) {
          stopoversList.add(
            SearchBookingStopoverModel.fromJson(
              s.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }

    return SearchBookingDetailsModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      publisherId: json['publisherId']?.toString() ?? driver.id,
      origin: origin,
      originAddress: originAddress,
      originCity: originCity,
      originLat: originLat,
      originLng: originLng,
      destination: destination,
      destinationAddress: destinationAddress,
      destinationCity: destinationCity,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      departureTime: depTime,
      availableSeats: availableSeats,
      totalSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      vehicleModel: json['vehicleModel']?.toString() ??
          json['vehicle']?.toString() ??
          'Standard Car',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      rideCode: json['rideCode']?.toString() ?? '',
      totalDistance: totalDist,
      distanceKm: distKm,
      hasToll: hasToll,
      tollType: tollType,
      durationText: durationText,
      tollRoute: tollRoute,
      stopovers: stopoversList,
      driver: driver,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'publisherId': publisherId,
    'origin': origin,
    'originAddress': originAddress,
    'originCity': originCity,
    'originLat': originLat,
    'originLng': originLng,
    'destination': destination,
    'destinationAddress': destinationAddress,
    'destinationCity': destinationCity,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'departureTime': departureTime.toIso8601String(),
    'availableSeats': availableSeats,
    'totalSeats': totalSeats,
    'pricePerSeat': pricePerSeat,
    'vehicleModel': vehicleModel,
    'vehicleNumber': vehicleNumber,
    'notes': notes,
    'status': status,
    'rideCode': rideCode,
    'totalDistance': totalDistance,
    'distanceKm': distanceKm,
    'hasToll': hasToll,
    'toll_type': tollType,
    'toll_route': tollRoute,
    'stopover': stopovers.map((s) => (s as SearchBookingStopoverModel).toJson()).toList(),
    'driver': {
      'id': driver.id,
      'name': driver.name,
      'phone': driver.phone,
      'rating': driver.rating,
      'totalTrips': driver.totalTrips,
    },
  };
}
