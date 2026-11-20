import 'package:equatable/equatable.dart';

class RouteCoordinate extends Equatable {
  final double lat;
  final double lng;

  const RouteCoordinate(this.lat, this.lng);

  @override
  List<Object?> get props => [lat, lng];
}

class CarpoolRouteOptionEntity extends Equatable {
  final String id;
  final String durationText;
  final int distanceKm;
  final bool hasTolls;
  final String highwayName;
  final List<RouteCoordinate> waypoints;
  final String corridorText;

  const CarpoolRouteOptionEntity({
    required this.id,
    required this.durationText,
    required this.distanceKm,
    required this.hasTolls,
    required this.highwayName,
    required this.waypoints,
    this.corridorText = '',
  });

  String get title => '$durationText • ${hasTolls ? 'Tolls' : 'No tolls'}';
  String get subtitle => '$distanceKm km • $highwayName';

  @override
  List<Object?> get props => [
    id,
    durationText,
    distanceKm,
    hasTolls,
    highwayName,
    waypoints,
    corridorText,
  ];
}

/// Dynamic intermediate city / town discovered along an actual driving route
class CarpoolStopoverCityEntity extends Equatable {
  final String name;
  final int distanceKm;
  final bool hasTolls;
  final bool isOnRoute;
  final int detourKm;
  final double lat;
  final double lng;
  final String? subtitle;

  const CarpoolStopoverCityEntity({
    required this.name,
    required this.distanceKm,
    required this.hasTolls,
    this.isOnRoute = true,
    this.detourKm = 0,
    required this.lat,
    required this.lng,
    this.subtitle,
  });

  @override
  List<Object?> get props => [
    name,
    distanceKm,
    hasTolls,
    isOnRoute,
    detourKm,
    lat,
    lng,
    subtitle,
  ];
}
