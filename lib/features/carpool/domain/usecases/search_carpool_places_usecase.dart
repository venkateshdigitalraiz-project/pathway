import '../entities/carpool_place_entity.dart';
import '../repositories/carpool_places_repository.dart';

class SearchCarpoolPlacesUseCase {
  final CarpoolPlacesRepository repository;

  const SearchCarpoolPlacesUseCase(this.repository);

  Future<List<CarpoolPlaceEntity>> call(String query) {
    return repository.searchPlaces(query);
  }
}
