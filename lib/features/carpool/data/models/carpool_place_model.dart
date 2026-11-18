import '../../domain/entities/carpool_place_entity.dart';

class CarpoolPlaceModel extends CarpoolPlaceEntity {
  const CarpoolPlaceModel({
    required super.id,
    required super.name,
    required super.formattedAddress,
    required super.type,
    required super.lat,
    required super.lng,
    super.district,
    super.state,
  });

  factory CarpoolPlaceModel.fromJson(Map<String, dynamic> json) {
    CarpoolPlaceType placeType = CarpoolPlaceType.locality;
    final typeStr =
        (json['type'] ?? json['place_type'] ?? json['osm_value'] ?? '')
            .toString()
            .toLowerCase();
    if (typeStr == 'city' || typeStr.contains('city')) {
      placeType = CarpoolPlaceType.city;
    } else if (typeStr == 'town' || typeStr.contains('town')) {
      placeType = CarpoolPlaceType.town;
    } else if (typeStr == 'village' ||
        typeStr.contains('village') ||
        typeStr == 'hamlet') {
      placeType = CarpoolPlaceType.village;
    } else {
      placeType = CarpoolPlaceType.locality;
    }

    return CarpoolPlaceModel(
      id: json['id']?.toString() ??
          '${json['name']}_${json['lat']}_${json['lng']}',
      name: json['name']?.toString() ?? '',
      formattedAddress: json['formattedAddress']?.toString() ??
          json['formatted_address']?.toString() ??
          json['address']?.toString() ??
          '',
      type: placeType,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formattedAddress': formattedAddress,
      'type': type.name,
      'lat': lat,
      'lng': lng,
      'district': district,
      'state': state,
    };
  }
}
