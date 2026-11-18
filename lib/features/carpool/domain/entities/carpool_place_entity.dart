import 'package:equatable/equatable.dart';

enum CarpoolPlaceType {
  city,
  town,
  village,
  locality;

  String get displayName {
    switch (this) {
      case CarpoolPlaceType.city:
        return 'City';
      case CarpoolPlaceType.town:
        return 'Town';
      case CarpoolPlaceType.village:
        return 'Village';
      case CarpoolPlaceType.locality:
        return 'Locality';
    }
  }
}

/// Domain entity representing a searchable location (City, Town, Village, Locality)
class CarpoolPlaceEntity extends Equatable {
  final String id;
  final String name;
  final String formattedAddress;
  final CarpoolPlaceType type;
  final double lat;
  final double lng;
  final String district;
  final String state;

  const CarpoolPlaceEntity({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.type,
    required this.lat,
    required this.lng,
    this.district = '',
    this.state = '',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        formattedAddress,
        type,
        lat,
        lng,
        district,
        state,
      ];
}
