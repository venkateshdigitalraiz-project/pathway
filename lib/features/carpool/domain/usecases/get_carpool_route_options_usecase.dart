import '../entities/carpool_place_entity.dart';
import '../entities/carpool_route_option_entity.dart';
import '../repositories/carpool_routes_repository.dart';

class GetCarpoolRouteOptionsUseCase {
  final CarpoolRoutesRepository repository;

  const GetCarpoolRouteOptionsUseCase(this.repository);

  Future<List<CarpoolRouteOptionEntity>> call({
    required CarpoolPlaceEntity origin,
    required CarpoolPlaceEntity destination,
  }) {
    return repository.getRouteOptions(
      origin: origin,
      destination: destination,
    );
  }
}
