import '../entities/carpool_place_entity.dart';
import '../repositories/carpool_places_repository.dart';

class GetPlaceFromCoordsUseCase {
  final CarpoolPlacesRepository repository;

  const GetPlaceFromCoordsUseCase(this.repository);

  Future<CarpoolPlaceEntity?> call(double lat, double lng) {
    return repository.getPlaceFromCoordinates(lat, lng);
  }
}
