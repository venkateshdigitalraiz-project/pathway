import '../entities/my_publish_ride_details_entity.dart';

/// Contract for fetching publisher ride details
abstract class MyPublishRideDetailsRepository {
  Future<MyPublishRideDetailsEntity> getPublishRideDetails(String rideId);
}
