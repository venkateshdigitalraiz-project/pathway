import '../entities/carpool_place_entity.dart';

abstract class CarpoolPlacesRepository {
  Future<List<CarpoolPlaceEntity>> searchPlaces(String query);
  Future<CarpoolPlaceEntity?> getPlaceFromCoordinates(double lat, double lng);
  Future<List<CarpoolPlaceEntity>> getPopularPlaces();
}
