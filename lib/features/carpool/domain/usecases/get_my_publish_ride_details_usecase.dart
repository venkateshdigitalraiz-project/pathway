import '../entities/my_publish_ride_details_entity.dart';
import '../repositories/my_publish_ride_details_repository.dart';

/// UseCase to fetch full publisher ride details by ride ID
class GetMyPublishRideDetailsUseCase {
  final MyPublishRideDetailsRepository repository;

  const GetMyPublishRideDetailsUseCase(this.repository);

  Future<MyPublishRideDetailsEntity> call(String rideId) {
    return repository.getPublishRideDetails(rideId);
  }
}
