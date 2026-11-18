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

  const CarpoolRouteOptionEntity({
    required this.id,
    required this.durationText,
    required this.distanceKm,
    required this.hasTolls,
    required this.highwayName,
    required this.waypoints,
  });

  String get title => '$durationText - ${hasTolls ? 'Tolls' : 'No tolls'}';
  String get subtitle => '$distanceKm km - $highwayName';

  @override
  List<Object?> get props => [
        id,
        durationText,
        distanceKm,
        hasTolls,
        highwayName,
        waypoints,
      ];
}
