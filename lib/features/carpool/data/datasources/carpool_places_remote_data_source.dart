import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../domain/entities/carpool_place_entity.dart';
import '../models/carpool_place_model.dart';

abstract class CarpoolPlacesRemoteDataSource {
  Future<List<CarpoolPlaceModel>> searchPlaces(String query);
  Future<CarpoolPlaceModel?> getPlaceFromCoordinates(double lat, double lng);
  Future<List<CarpoolPlaceModel>> getPopularPlaces();
}

class CarpoolPlacesRemoteDataSourceImpl implements CarpoolPlacesRemoteDataSource {
  final String apiKey;
  final HttpClient _client;

  CarpoolPlacesRemoteDataSourceImpl({
    String? apiKey,
    HttpClient? client,
  })  : apiKey = apiKey ?? ApiEndpoints.googleMapsApiKey,
        _client = client ?? HttpClient();

  @override
  Future<List<CarpoolPlaceModel>> getPopularPlaces() async {
    return _defaultPopularPlaces;
  }

  @override
  Future<List<CarpoolPlaceModel>> searchPlaces(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return getPopularPlaces();
    }

    final results = <CarpoolPlaceModel>[];
    final seen = <String>{};

    void addIfUnique(CarpoolPlaceModel item) {
      final key =
          '${item.name.toLowerCase()}_${item.lat.toStringAsFixed(3)}_${item.lng.toStringAsFixed(3)}';
      if (!seen.contains(key)) {
        seen.add(key);
        results.add(item);
      }
    }

    // 1. Primary: Real-Time Dynamic OpenStreetMap Photon Geocoder (India Bounded)
    // Works 100% reliably without requiring any Google Cloud billing or API key!
    try {
      final photonList = await _fetchFromPhoton(clean);
      for (final p in photonList) {
        addIfUnique(p);
      }
      if (results.isNotEmpty) {
        return results;
      }
    } catch (_) {}

    // 2. Secondary: Real-Time Live OpenStreetMap Nominatim Geocoder (India Bounded)
    try {
      final nominatimList = await _fetchFromNominatim(clean);
      for (final p in nominatimList) {
        addIfUnique(p);
      }
      if (results.isNotEmpty) {
        return results;
      }
    } catch (_) {}

    // 3. Tertiary: Google Places API (if key is valid and online)
    if (apiKey.isNotEmpty) {
      try {
        final googleList = await _fetchFromGooglePlaces(clean);
        for (final p in googleList) {
          addIfUnique(p);
        }
        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {}
    }

    // 4. Offline Fallback: Local regional coordinates lookup
    final match = CarpoolDistanceCalculator.findGeo(clean);
    if (match != null) {
      addIfUnique(
        CarpoolPlaceModel(
          id: 'geo_${clean.toLowerCase()}_${match.lat}',
          name: match.name.isNotEmpty ? match.name : clean,
          formattedAddress:
              '${match.district.isNotEmpty ? '${match.district}, ' : ''}${match.state.isNotEmpty ? match.state : 'India'}',
          type: match.type.toLowerCase().contains('village')
              ? CarpoolPlaceType.village
              : match.type.toLowerCase().contains('town')
                  ? CarpoolPlaceType.town
                  : CarpoolPlaceType.city,
          lat: match.lat,
          lng: match.lng,
          district: match.district,
          state: match.state,
        ),
      );
    } else {
      final coords = CarpoolDistanceCalculator.resolveCoordinates(clean);
      if (coords.lat != 0.0 && coords.lng != 0.0) {
        addIfUnique(
          CarpoolPlaceModel(
            id: 'coord_${clean.toLowerCase()}_${coords.lat}',
            name: clean,
            formattedAddress: 'India',
            type: CarpoolPlaceType.city,
            lat: coords.lat,
            lng: coords.lng,
          ),
        );
      }
    }

    return results;
  }

  /// Fetches places from Photon (OpenStreetMap Elasticsearch geocoder).
  /// Strictly constrained to India with bounding box and coordinate boundaries.
  Future<List<CarpoolPlaceModel>> _fetchFromPhoton(String query) async {
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=15&bbox=68.1,6.7,97.4,37.1',
    );
    final req = await _client.getUrl(uri).timeout(const Duration(seconds: 4));
    req.headers.set('User-Agent', 'PathwayCarpoolApp/1.0');
    final res = await req.close().timeout(const Duration(seconds: 4));

    if (res.statusCode != 200) return const [];

    final body = await res.transform(utf8.decoder).join();
    final map = jsonDecode(body) as Map<String, dynamic>;
    final features = map['features'] as List<dynamic>? ?? [];

    final results = <CarpoolPlaceModel>[];

    for (final f in features) {
      final geom = f['geometry'] as Map<String, dynamic>?;
      final props = f['properties'] as Map<String, dynamic>? ?? {};

      final coords = geom?['coordinates'] as List<dynamic>?;
      final double? lng = (coords != null && coords.isNotEmpty)
          ? (coords[0] as num).toDouble()
          : null;
      final double? lat = (coords != null && coords.length > 1)
          ? (coords[1] as num).toDouble()
          : null;

      if (lat == null || lng == null) continue;
      if (lat < 6.5 || lat > 38.0 || lng < 68.0 || lng > 98.0) continue;

      final country = (props['country'] ?? '') as String;
      if (country.isNotEmpty &&
          country.toLowerCase() != 'india' &&
          country.toLowerCase() != 'in') {
        continue;
      }

      final name =
          ((props['name'] ?? props['city'] ?? props['locality'] ?? '') as String)
              .trim();
      if (name.isEmpty) continue;

      final state = (props['state'] ?? '') as String;
      final district = (props['district'] ?? props['county'] ?? '') as String;
      final osmValue =
          (props['osm_value'] ?? props['type'] ?? '').toString().toLowerCase();

      CarpoolPlaceType placeType;
      if (osmValue == 'city') {
        placeType = CarpoolPlaceType.city;
      } else if (osmValue == 'town') {
        placeType = CarpoolPlaceType.town;
      } else if (osmValue == 'village' || osmValue == 'hamlet') {
        placeType = CarpoolPlaceType.village;
      } else {
        placeType = CarpoolPlaceType.locality;
      }

      final addressParts = <String>[];
      if (district.isNotEmpty && district.toLowerCase() != name.toLowerCase()) {
        addressParts.add(district);
      }
      if (state.isNotEmpty) addressParts.add(state);
      addressParts.add('India');
      final formattedAddress = addressParts.join(', ');

      // Register live coordinates into cache
      CarpoolDistanceCalculator.registerGeo(
        name,
        lat,
        lng,
        type: osmValue.isNotEmpty ? osmValue : 'Location',
        district: district,
        state: state,
      );

      results.add(
        CarpoolPlaceModel(
          id: 'photon_${props['osm_id'] ?? '${name}_$lat'}',
          name: name,
          formattedAddress: formattedAddress,
          type: placeType,
          lat: lat,
          lng: lng,
          district: district,
          state: state,
        ),
      );
    }

    return results;
  }

  /// Fetches places from OpenStreetMap Nominatim Live Geocoder
  Future<List<CarpoolPlaceModel>> _fetchFromNominatim(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'countrycodes': 'in',
      'format': 'json',
      'addressdetails': '1',
      'limit': '15',
    });

    final req = await _client.getUrl(uri).timeout(const Duration(seconds: 4));
    req.headers.set('User-Agent', 'PathwayCarpoolApp/1.0');
    final res = await req.close().timeout(const Duration(seconds: 4));

    if (res.statusCode != 200) return const [];

    final body = await res.transform(utf8.decoder).join();
    final list = jsonDecode(body) as List<dynamic>? ?? [];

    final results = <CarpoolPlaceModel>[];

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final double lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
      final double lng = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
      if (lat < 6.5 || lat > 38.0 || lng < 68.0 || lng > 98.0) continue;

      final address = item['address'] as Map<String, dynamic>? ?? {};
      final name = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['suburb'] ??
          address['county'] ??
          item['name'] ??
          '';

      if (name.toString().trim().isEmpty) continue;

      final state = address['state']?.toString() ?? '';
      final district = address['county']?.toString() ?? '';
      final typeStr = (item['type'] ?? item['class'] ?? '').toString().toLowerCase();

      CarpoolPlaceType placeType;
      if (typeStr.contains('city')) {
        placeType = CarpoolPlaceType.city;
      } else if (typeStr.contains('town')) {
        placeType = CarpoolPlaceType.town;
      } else if (typeStr.contains('village') || typeStr.contains('hamlet')) {
        placeType = CarpoolPlaceType.village;
      } else {
        placeType = CarpoolPlaceType.locality;
      }

      results.add(
        CarpoolPlaceModel(
          id: 'nom_${item['place_id'] ?? '${lat}_$lng'}',
          name: name.toString().trim(),
          formattedAddress: item['display_name']?.toString() ?? '$name, India',
          type: placeType,
          lat: lat,
          lng: lng,
          district: district,
          state: state,
        ),
      );
    }

    return results;
  }

  /// Live Google Places API Fallback
  Future<List<CarpoolPlaceModel>> _fetchFromGooglePlaces(String query) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
    final req = await _client.postUrl(uri).timeout(const Duration(seconds: 4));
    req.headers.set('X-Goog-Api-Key', apiKey);
    req.headers.set('Content-Type', 'application/json');
    req.write(
      jsonEncode({
        'input': query,
        'includedRegionCodes': ['in'],
      }),
    );

    final res = await req.close().timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return const [];

    final body = await res.transform(utf8.decoder).join();
    final map = jsonDecode(body) as Map<String, dynamic>;
    final suggestions = map['suggestions'] as List<dynamic>? ?? [];

    final results = <CarpoolPlaceModel>[];
    for (final s in suggestions) {
      final pPred = s['placePrediction'] as Map<String, dynamic>?;
      if (pPred == null) continue;

      final textObj = pPred['text'] as Map<String, dynamic>?;
      final mainTextObj =
          (pPred['structuredFormat']?['mainText'] ?? textObj) as Map<String, dynamic>?;
      final name = mainTextObj?['text']?.toString() ?? '';
      final formatted = textObj?['text']?.toString() ?? name;

      final coords = CarpoolDistanceCalculator.resolveCoordinates(name);
      if (coords.lat == 0.0) continue;

      results.add(
        CarpoolPlaceModel(
          id: pPred['placeId']?.toString() ?? name,
          name: name,
          formattedAddress: formatted,
          type: CarpoolPlaceType.city,
          lat: coords.lat,
          lng: coords.lng,
        ),
      );
    }

    return results;
  }

  @override
  Future<CarpoolPlaceModel?> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final req = await _client.getUrl(uri).timeout(const Duration(seconds: 4));
      req.headers.set('User-Agent', 'PathwayCarpoolApp/1.0');
      final res = await req.close().timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final map = jsonDecode(body) as Map<String, dynamic>;
        final address = map['address'] as Map<String, dynamic>? ?? {};

        final name = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['suburb'] ??
            address['neighbourhood'] ??
            address['road'] ??
            'Selected Location';

        CarpoolPlaceType type = CarpoolPlaceType.locality;
        if (address.containsKey('city')) {
          type = CarpoolPlaceType.city;
        } else if (address.containsKey('town')) {
          type = CarpoolPlaceType.town;
        } else if (address.containsKey('village') || address.containsKey('hamlet')) {
          type = CarpoolPlaceType.village;
        }

        return CarpoolPlaceModel(
          id: 'rev_${lat}_$lng',
          name: name.toString(),
          formattedAddress: map['display_name']?.toString() ?? '$name, India',
          type: type,
          lat: lat,
          lng: lng,
          district: address['county']?.toString() ?? '',
          state: address['state']?.toString() ?? '',
        );
      }
    } catch (_) {}

    return CarpoolPlaceModel(
      id: 'rev_${lat}_$lng',
      name: 'Pinned Location',
      formattedAddress:
          'Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      type: CarpoolPlaceType.locality,
      lat: lat,
      lng: lng,
    );
  }

  static final List<CarpoolPlaceModel> _defaultPopularPlaces = [
    const CarpoolPlaceModel(
      id: 'city_hyd',
      name: 'Hyderabad',
      formattedAddress: 'Telangana, India',
      type: CarpoolPlaceType.city,
      lat: 17.3850,
      lng: 78.4867,
      district: 'Hyderabad',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'city_vja',
      name: 'Vijayawada',
      formattedAddress: 'Andhra Pradesh, India',
      type: CarpoolPlaceType.city,
      lat: 16.5062,
      lng: 80.6480,
      district: 'Krishna',
      state: 'Andhra Pradesh',
    ),
    const CarpoolPlaceModel(
      id: 'city_sec',
      name: 'Secunderabad',
      formattedAddress: 'Telangana, India',
      type: CarpoolPlaceType.city,
      lat: 17.4399,
      lng: 78.4983,
      district: 'Hyderabad',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'city_wgl',
      name: 'Warangal',
      formattedAddress: 'Telangana, India',
      type: CarpoolPlaceType.city,
      lat: 17.9689,
      lng: 79.5941,
      district: 'Warangal',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'city_krm',
      name: 'Karimnagar',
      formattedAddress: 'Telangana, India',
      type: CarpoolPlaceType.city,
      lat: 18.4386,
      lng: 79.1288,
      district: 'Karimnagar',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'town_suryapet',
      name: 'Suryapet',
      formattedAddress: 'Suryapet District, Telangana, India',
      type: CarpoolPlaceType.town,
      lat: 17.1439,
      lng: 79.6239,
      district: 'Suryapet',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'town_nalgonda',
      name: 'Nalgonda',
      formattedAddress: 'Nalgonda District, Telangana, India',
      type: CarpoolPlaceType.town,
      lat: 17.0575,
      lng: 79.2684,
      district: 'Nalgonda',
      state: 'Telangana',
    ),
    const CarpoolPlaceModel(
      id: 'town_kodad',
      name: 'Kodad',
      formattedAddress: 'Suryapet District, Telangana, India',
      type: CarpoolPlaceType.town,
      lat: 16.9967,
      lng: 79.9678,
      district: 'Suryapet',
      state: 'Telangana',
    ),
  ];
}
