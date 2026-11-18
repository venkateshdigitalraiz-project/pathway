import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/entities/carpool_route_option_entity.dart';
import '../../domain/repositories/carpool_routes_repository.dart';
import '../datasources/carpool_routes_remote_data_source.dart';

class CarpoolRoutesRepositoryImpl implements CarpoolRoutesRepository {
  final CarpoolRoutesRemoteDataSource remoteDataSource;

  CarpoolRoutesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CarpoolRouteOptionEntity>> getRouteOptions({
    required CarpoolPlaceEntity origin,
    required CarpoolPlaceEntity destination,
  }) {
    return remoteDataSource.getRouteOptions(
      origin: origin,
      destination: destination,
    );
  }
}
