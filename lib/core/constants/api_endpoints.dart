class ApiEndpoints {
  ApiEndpoints._();

  /// Google Maps & Places API Key
  static const String googleMapsApiKey =
      'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU';

  /// Base URL of the backend API
  static const String baseUrl = 'http://192.168.0.161:5001';

  /// Socket.IO URL
  static const String socketUrl = baseUrl;

  /// Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String sendOtp = login;
  static const String verifyOtp = login;
  static const String logout = '$baseUrl/api/auth/logout';

  /// User profile endpoint
  static const String userProfile = '$baseUrl/api/users/profile';

  /// Settings endpoints
  static const String carpoolSettings = '$baseUrl/api/settings/carpool';

  /// Carpool endpoints
  static const String calculatePricing =
      '$baseUrl/api/carpool/pricing/calculate';
  static const String publishRide =
      '$baseUrl/api/carpool/rides/publish';
  static const String myPublishedRides =
      '$baseUrl/api/carpool/my-published-rides';
  static const String myBookings = '$baseUrl/api/carpool/my-bookings';
  static const String rides = '$baseUrl/api/carpool/rides';
  static const String searchRides = '$baseUrl/api/carpool/rides/search';
  static String searchRideDetails(String id) =>
      '$baseUrl/api/carpool/rides/search/$id';
  static String rideDetails(String id) => '$baseUrl/api/carpool/rides/$id';
  static String bookRide(String id) => '$baseUrl/api/carpool/rides/$id/book';
  static String acceptBooking(String id) =>
      '$baseUrl/api/carpool/bookings/$id/accept';
  static String rejectBooking(String id) =>
      '$baseUrl/api/carpool/bookings/$id/reject';
  static String cancelBooking(String id) =>
      '$baseUrl/api/carpool/bookings/$id/cancel';
  static String cancelRide(String id) =>
      '$baseUrl/api/carpool/rides/$id/cancel';
}
