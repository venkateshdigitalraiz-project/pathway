import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/repositories/carpool_places_repository.dart';
import '../datasources/carpool_places_remote_data_source.dart';

class CarpoolPlacesRepositoryImpl implements CarpoolPlacesRepository {
  final CarpoolPlacesRemoteDataSource remoteDataSource;

  CarpoolPlacesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CarpoolPlaceEntity>> searchPlaces(String query) async {
    return remoteDataSource.searchPlaces(query);
  }

  @override
  Future<CarpoolPlaceEntity?> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    return remoteDataSource.getPlaceFromCoordinates(lat, lng);
  }

  @override
  Future<List<CarpoolPlaceEntity>> getPopularPlaces() async {
    return remoteDataSource.getPopularPlaces();
  }
}
