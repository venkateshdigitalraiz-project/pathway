import '../../domain/entities/carpool_route_option_entity.dart';

class CarpoolRouteOptionModel extends CarpoolRouteOptionEntity {
  const CarpoolRouteOptionModel({
    required super.id,
    required super.durationText,
    required super.distanceKm,
    required super.hasTolls,
    required super.highwayName,
    required super.waypoints,
  });

  factory CarpoolRouteOptionModel.fromJson(Map<String, dynamic> json) {
    final rawWaypoints = (json['waypoints'] as List<dynamic>?) ?? [];
    final waypoints = rawWaypoints.map((w) {
      if (w is Map<String, dynamic>) {
        return RouteCoordinate(
          (w['lat'] as num).toDouble(),
          (w['lng'] as num).toDouble(),
        );
      }
      return const RouteCoordinate(0, 0);
    }).toList();

    return CarpoolRouteOptionModel(
      id: json['id']?.toString() ?? '',
      durationText: json['durationText']?.toString() ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toInt() ?? 0,
      hasTolls: json['hasTolls'] as bool? ?? true,
      highwayName: json['highwayName']?.toString() ?? 'Highway',
      waypoints: waypoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'durationText': durationText,
      'distanceKm': distanceKm,
      'hasTolls': hasTolls,
      'highwayName': highwayName,
      'waypoints': waypoints.map((w) => {'lat': w.lat, 'lng': w.lng}).toList(),
    };
  }
}
