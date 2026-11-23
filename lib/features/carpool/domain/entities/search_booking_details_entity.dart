import 'package:equatable/equatable.dart';

/// Driver Details Entity
class DriverDetailsEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int totalTrips;

  const DriverDetailsEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.totalTrips = 0,
  });

  @override
  List<Object?> get props => [id, name, phone, rating, totalTrips];
}

/// Stopover / Via Halt along the ride route
class SearchBookingStopoverEntity extends Equatable {
  final int order;
  final String city;
  final String address;
  final String state;
  final double latitude;
  final double longitude;

  const SearchBookingStopoverEntity({
    required this.order,
    required this.city,
    required this.address,
    this.state = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  @override
  List<Object?> get props => [order, city, address, state, latitude, longitude];
}

/// Search Booking Details Entity (matching GET /api/carpool/rides/search/:id response)
class SearchBookingDetailsEntity extends Equatable {
  final String id;
  final String publisherId;
  final String origin;
  final String originAddress;
  final String originCity;
  final double originLat;
  final double originLng;

  final String destination;
  final String destinationAddress;
  final String destinationCity;
  final double destinationLat;
  final double destinationLng;

  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final int pricePerSeat;
  final String vehicleModel;
  final String vehicleNumber;
  final String notes;
  final String status;
  final String rideCode;

  final double totalDistance;
  final double distanceKm;
  final bool hasToll;
  final String tollType;
  final String? durationText;
  final Map<String, dynamic>? tollRoute;
  final List<SearchBookingStopoverEntity> stopovers;
  final DriverDetailsEntity driver;

  const SearchBookingDetailsEntity({
    required this.id,
    required this.publisherId,
    required this.origin,
    this.originAddress = '',
    this.originCity = '',
    required this.originLat,
    required this.originLng,
    required this.destination,
    this.destinationAddress = '',
    this.destinationCity = '',
    required this.destinationLat,
    required this.destinationLng,
    required this.departureTime,
    required this.availableSeats,
    this.totalSeats = 1,
    required this.pricePerSeat,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.notes,
    this.status = 'active',
    this.rideCode = '',
    this.totalDistance = 0.0,
    this.distanceKm = 0.0,
    this.hasToll = false,
    this.tollType = 'no_toll',
    this.durationText,
    this.tollRoute,
    this.stopovers = const [],
    required this.driver,
  });

  /// Clean readable title for the vehicle
  String get vehicleTitle {
    if (vehicleModel.isEmpty && vehicleNumber.isEmpty) return 'Standard Car';
    if (vehicleNumber.isEmpty) return vehicleModel;
    return '$vehicleModel • $vehicleNumber';
  }

  /// Clean place helpers for display
  String get cleanOrigin {
    if (originCity.isNotEmpty) return originCity;
    if (originAddress.isNotEmpty) return originAddress;
    return _cleanLocation(origin);
  }

  String get cleanDestination {
    if (destinationCity.isNotEmpty) return destinationCity;
    if (destinationAddress.isNotEmpty) return destinationAddress;
    return _cleanLocation(destination);
  }

  /// Formatted duration / estimated journey time from toll_route or durationText
  String get estimatedDuration {
    if (durationText != null && durationText!.trim().isNotEmpty) {
      return durationText!.trim();
    }
    if (tollRoute != null && tollRoute!['duration'] != null) {
      final d = tollRoute!['duration'].toString().trim();
      if (d.isNotEmpty) return d;
    }
    final dist = distanceKm > 0 ? distanceKm : totalDistance;
    if (dist > 0) {
      final hours = dist.toInt() ~/ 60;
      final mins = ((dist % 60) * 60 / 60).round();
      if (hours > 0 && mins > 0) return '$hours hr $mins min';
      if (hours > 0) return '$hours hr';
      return '$mins min';
    }
    return '';
  }

  /// Formatted total distance
  String get displayDistance {
    if (tollRoute != null && tollRoute!['distance'] != null) {
      final d = (tollRoute!['distance'] as num?)?.toDouble();
      if (d != null && d > 0) {
        return '${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1)} km';
      }
    }
    final dist = totalDistance > 0 ? totalDistance : distanceKm;
    if (dist > 0) {
      return '${dist.toStringAsFixed(dist.truncateToDouble() == dist ? 0 : 1)} km';
    }
    return '';
  }

  static String _cleanLocation(String raw) {
    if (raw.isEmpty) return '';
    var cleaned = raw.replaceAll(RegExp(r'''[{}"]'''), '').trim();
    final addrMatch = RegExp(
      r'(?:address|place|name)\s*[:=]\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (addrMatch != null) {
      cleaned = addrMatch.group(1)?.trim() ?? cleaned;
    }
    return cleaned;
  }

  @override
  List<Object?> get props => [
    id,
    publisherId,
    origin,
    originAddress,
    originCity,
    originLat,
    originLng,
    destination,
    destinationAddress,
    destinationCity,
    destinationLat,
    destinationLng,
    departureTime,
    availableSeats,
    totalSeats,
    pricePerSeat,
    vehicleModel,
    vehicleNumber,
    notes,
    status,
    rideCode,
    totalDistance,
    distanceKm,
    hasToll,
    tollType,
    durationText,
    tollRoute,
    stopovers,
    driver,
  ];
}
