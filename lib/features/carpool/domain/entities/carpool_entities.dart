import 'package:equatable/equatable.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../../../core/utils/carpool_formatters.dart';

enum CarpoolRideStatus { upcoming, completed, cancelled }

enum CarpoolRideType { normal, premium }

enum CarpoolDayFilter { today, tomorrow, anyTime }

enum CarpoolTransactionType { payment, reward, topUp }

enum CarpoolMessageCategory { rides, support, system }

class CarpoolUserEntity extends Equatable {
  const CarpoolUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.rating,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String email;
  final double rating;
  final bool isPremium;

  @override
  List<Object?> get props => [id, name, email, rating, isPremium];
}

class CarpoolPopularRouteEntity extends Equatable {
  const CarpoolPopularRouteEntity({
    required this.from,
    required this.to,
    required this.price,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  final String from;
  final String to;
  final int price;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  @override
  List<Object?> get props => [from, to, price, fromLat, fromLng, toLat, toLng];
}

class CarpoolRideEntity extends Equatable {
  const CarpoolRideEntity({
    required this.id,
    required this.driverName,
    required this.driverRating,
    required this.driverTrips,
    required this.vehicle,
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.pricePerSeat,
    required this.distanceKm,
    required this.status,
    required this.rideType,
    this.totalBookings = 0,
    this.vehicleModel,
    this.vehicleNumber,
    this.originCity,
    this.destinationCity,
    this.rideCode,
    this.driverPhone,
    this.notes,
    this.durationText,
    this.totalDistance,
    this.hasToll,
    this.tollType,
    this.tollRoute,
    this.stopovers,
  });

  final String id;
  final String driverName;
  final double driverRating;
  final int driverTrips;
  final String vehicle;
  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final int pricePerSeat;
  final int distanceKm;
  final CarpoolRideStatus status;
  final CarpoolRideType rideType;
  final int totalBookings;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? originCity;
  final String? destinationCity;
  final String? rideCode;
  final String? driverPhone;
  final String? notes;
  final String? durationText;
  final double? totalDistance;
  final bool? hasToll;
  final String? tollType;
  final Map<String, dynamic>? tollRoute;
  final List<Map<String, dynamic>>? stopovers;

  String get displayFromCity =>
      (originCity != null && originCity!.isNotEmpty) ? originCity! : from;

  String get displayToCity =>
      (destinationCity != null && destinationCity!.isNotEmpty)
      ? destinationCity!
      : to;

  /// Formatted duration / estimated journey time from toll_route or durationText
  String get estimatedDuration {
    if (durationText != null && durationText!.trim().isNotEmpty) {
      return durationText!.trim();
    }
    if (tollRoute != null && tollRoute!['duration'] != null) {
      final d = tollRoute!['duration'].toString().trim();
      if (d.isNotEmpty) return d;
    }
    if (distanceKm > 0) {
      final hours = distanceKm ~/ 60;
      final mins = ((distanceKm % 60) * 60 / 60).round();
      if (hours > 0 && mins > 0) return '$hours hr $mins min';
      if (hours > 0) return '$hours hr';
      return '$mins min';
    }
    return '';
  }

  /// Formatted distance from toll_route, totalDistance, or distanceKm
  String get displayDistance {
    if (tollRoute != null && tollRoute!['distance'] != null) {
      final d = (tollRoute!['distance'] as num?)?.toDouble();
      if (d != null && d > 0) {
        return '${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1)} km';
      }
    }
    if (totalDistance != null && totalDistance! > 0) {
      return '${totalDistance!.toStringAsFixed(totalDistance!.truncateToDouble() == totalDistance ? 0 : 1)} km';
    }
    if (distanceKm > 0) {
      return '$distanceKm km';
    }
    return '';
  }

  CarpoolRideEntity copyWith({
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
  }) {
    return CarpoolRideEntity(
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

  @override
  List<Object?> get props => [
    id,
    driverName,
    driverRating,
    driverTrips,
    vehicle,
    from,
    to,
    departure,
    seats,
    pricePerSeat,
    distanceKm,
    status,
    rideType,
    totalBookings,
    vehicleModel,
    vehicleNumber,
    originCity,
    destinationCity,
    rideCode,
    driverPhone,
    notes,
    durationText,
    totalDistance,
    hasToll,
    tollType,
    tollRoute,
    stopovers,
  ];
}

class CarpoolPublishRideParams extends Equatable {
  const CarpoolPublishRideParams({
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.rideType,
    this.pricePerSeat,
    this.vehicle,
    this.origin,
    this.originLat,
    this.originLng,
    this.originCity,
    this.destination,
    this.destinationLat,
    this.destinationLng,
    this.destinationCity,
    this.departureTime,
    this.availableSeats,
    this.vehicleModel,
    this.vehicleNumber,
    this.notes,
    this.totalDistance,
    this.distanceKm,
    this.hasToll,
    this.tollType,
    this.stopover,
    this.tollRoute,
  });

  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final CarpoolRideType rideType;
  final int? pricePerSeat;
  final String? vehicle;

  final String? origin;
  final double? originLat;
  final double? originLng;
  final String? originCity;
  final String? destination;
  final double? destinationLat;
  final double? destinationLng;
  final String? destinationCity;
  final String? departureTime;
  final int? availableSeats;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? notes;
  final double? totalDistance;
  final double? distanceKm;
  final bool? hasToll;
  final String? tollType;
  final List<Map<String, dynamic>>? stopover;
  final Map<String, dynamic>? tollRoute;

  Map<String, dynamic> toJson() {
    final resolvedOrigin = origin ?? from;
    final resolvedDest = destination ?? to;

    final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
      resolvedOrigin,
      preferredLat: originLat,
      preferredLng: originLng,
    );
    final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
      resolvedDest,
      preferredLat: destinationLat,
      preferredLng: destinationLng,
    );

    final resolvedOriginLat = originCoords.lat;
    final resolvedOriginLng = originCoords.lng;
    final resolvedOriginCity =
        originCity ??
        (resolvedOrigin.contains(',')
            ? resolvedOrigin.split(',').first.trim()
            : resolvedOrigin);

    final resolvedDestLat = destCoords.lat;
    final resolvedDestLng = destCoords.lng;
    final resolvedDestCity =
        destinationCity ??
        (resolvedDest.contains(',')
            ? resolvedDest.split(',').first.trim()
            : resolvedDest);

    DateTime dtToFormat = departure;
    if (departureTime != null && departureTime!.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(departureTime!);
      if (parsed != null) {
        dtToFormat = parsed;
      }
    }
    final formattedUtcDepartureTime = CarpoolFormatters.toUtcIso(dtToFormat);

    final resolvedDist = totalDistance ??
        distanceKm ??
        CarpoolDistanceCalculator.calculateDistanceKm(
          resolvedOrigin,
          resolvedDest,
          fromLat: resolvedOriginLat,
          fromLng: resolvedOriginLng,
          toLat: resolvedDestLat,
          toLng: resolvedDestLng,
        ).toDouble();

    final effectiveHasToll = hasToll ?? false;
    final effectiveTollType =
        tollType ?? (effectiveHasToll ? 'toll' : 'no_toll');

    final effectiveTollRoute = tollRoute ??
        {
          'type': effectiveTollType,
          'duration': '1 hour 15 mins',
          'distance': resolvedDist,
        };

    return {
      'origin': resolvedOrigin,
      'originLat': resolvedOriginLat,
      'originLng': resolvedOriginLng,
      'originCity': resolvedOriginCity,
      'destination': resolvedDest,
      'destinationLat': resolvedDestLat,
      'destinationLng': resolvedDestLng,
      'destinationCity': resolvedDestCity,
      'departureTime': formattedUtcDepartureTime,
      'availableSeats': availableSeats ?? seats,
      'pricePerSeat': pricePerSeat ?? 100,
      'vehicleModel': (vehicleModel != null && vehicleModel!.trim().isNotEmpty)
          ? vehicleModel!.trim()
          : (vehicle ?? 'Honda City'),
      'vehicleNumber':
          (vehicleNumber != null && vehicleNumber!.trim().isNotEmpty)
          ? vehicleNumber!.trim()
          : 'DL 01 AB 1234',
      'notes': notes ?? 'Direct highway drive, air-conditioned.',
      'totalDistance': resolvedDist,
      'distanceKm': resolvedDist,
      'hasToll': effectiveHasToll,
      'toll_type': effectiveTollType,
      'stopover': stopover ?? const <Map<String, dynamic>>[],
      'toll_route': effectiveTollRoute,
    };
  }

  @override
  List<Object?> get props => [
    from,
    to,
    departure,
    seats,
    rideType,
    pricePerSeat,
    vehicle,
    origin,
    originLat,
    originLng,
    originCity,
    destination,
    destinationLat,
    destinationLng,
    destinationCity,
    departureTime,
    availableSeats,
    vehicleModel,
    vehicleNumber,
    notes,
    totalDistance,
    distanceKm,
    hasToll,
    tollType,
    stopover,
    tollRoute,
  ];
}

class CarpoolSearchRidesParams extends Equatable {
  const CarpoolSearchRidesParams({
    required this.from,
    required this.to,
    required this.filter,
  });

  final String from;
  final String to;
  final CarpoolDayFilter filter;

  @override
  List<Object?> get props => [from, to, filter];
}

class CarpoolTransactionEntity extends Equatable {
  const CarpoolTransactionEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
  });

  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final CarpoolTransactionType type;

  @override
  List<Object?> get props => [id, title, date, amount, type];
}

class CarpoolWalletEntity extends Equatable {
  const CarpoolWalletEntity({
    required this.balance,
    required this.transactions,
  });

  final double balance;
  final List<CarpoolTransactionEntity> transactions;

  @override
  List<Object?> get props => [balance, transactions];
}

class CarpoolMessageEntity extends Equatable {
  const CarpoolMessageEntity({
    required this.id,
    required this.senderName,
    required this.preview,
    required this.timeAgo,
    required this.unreadCount,
    required this.category,
  });

  final String id;
  final String senderName;
  final String preview;
  final String timeAgo;
  final int unreadCount;
  final CarpoolMessageCategory category;

  @override
  List<Object?> get props => [
    id,
    senderName,
    preview,
    timeAgo,
    unreadCount,
    category,
  ];
}
