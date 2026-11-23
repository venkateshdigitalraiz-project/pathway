import 'package:equatable/equatable.dart';

/// Clean Architecture domain entity representing a validated stopover city along a driving route.
///
/// Contains complete location details:
/// - [latitude]: Geographical latitude coordinate.
/// - [longitude]: Geographical longitude coordinate.
/// - [address]: Full formatted address or corridor description.
/// - [state]: State or region name (e.g. Telangana, Andhra Pradesh).
/// - [city]: Name of the city / town.
class CarpoolStopoverEntity extends Equatable {
  final int order;
  final double latitude;
  final double longitude;
  final String address;
  final String state;
  final String city;

  const CarpoolStopoverEntity({
    this.order = 0,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.state,
    required this.city,
  });

  /// Convenience getters for coordinate access
  double get lat => latitude;
  double get lng => longitude;
  String get name => city.isNotEmpty ? city : address;

  CarpoolStopoverEntity copyWith({
    int? order,
    double? latitude,
    double? longitude,
    String? address,
    String? state,
    String? city,
  }) {
    return CarpoolStopoverEntity(
      order: order ?? this.order,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'state': state,
        'city': city,
      };

  factory CarpoolStopoverEntity.fromJson(Map<String, dynamic> json) {
    return CarpoolStopoverEntity(
      order: (json['order'] as num?)?.toInt() ??
          (json['stopOrder'] as num?)?.toInt() ??
          0,
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          0.0,
      address: json['address'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [order, latitude, longitude, address, state, city];

  @override
  String toString() =>
      'CarpoolStopoverEntity(city: $city, state: $state, lat: $latitude, lng: $longitude, address: $address)';
}
