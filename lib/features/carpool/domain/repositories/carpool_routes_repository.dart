import '../entities/carpool_place_entity.dart';
import '../entities/carpool_route_option_entity.dart';

abstract class CarpoolRoutesRepository {
  Future<List<CarpoolRouteOptionEntity>> getRouteOptions({
    required CarpoolPlaceEntity origin,
    required CarpoolPlaceEntity destination,
  });
}
