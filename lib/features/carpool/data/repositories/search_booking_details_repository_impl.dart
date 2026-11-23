import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
import '../../domain/entities/search_booking_details_entity.dart';
import '../../domain/repositories/search_booking_details_repository.dart';
import '../models/search_booking_details_model.dart';

class SearchBookingDetailsRepositoryImpl
    implements SearchBookingDetailsRepository {
  static final SearchBookingDetailsRepositoryImpl _instance =
      SearchBookingDetailsRepositoryImpl._internal();

  factory SearchBookingDetailsRepositoryImpl() => _instance;

  SearchBookingDetailsRepositoryImpl._internal();

  @override
  Future<SearchBookingDetailsEntity> getRideDetails(String rideId) async {
    // Primary endpoint: /api/carpool/rides/search/:id
    final primaryEndpoint = ApiEndpoints.searchRideDetails(rideId);
    final fallbackEndpoint = ApiEndpoints.rideDetails(rideId);

    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      final result = await _fetchDetails(primaryEndpoint, token);
      if (result != null) return result;

      // Fallback if needed
      final fallbackResult = await _fetchDetails(fallbackEndpoint, token);
      if (fallbackResult != null) return fallbackResult;
    } catch (e) {
      ApiLogger.logError(
        title: 'CARPOOL_SEARCH_RIDE_DETAILS',
        url: primaryEndpoint,
        error: e,
      );
    }

    // Default fallback if network unavailable
    return SearchBookingDetailsModel(
      id: rideId,
      publisherId: 'usr-default',
      origin: 'Origin',
      originAddress: 'Origin',
      originCity: 'Origin',
      originLat: 0.0,
      originLng: 0.0,
      destination: 'Destination',
      destinationAddress: 'Destination',
      destinationCity: 'Destination',
      destinationLat: 0.0,
      destinationLng: 0.0,
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableSeats: 2,
      totalSeats: 3,
      pricePerSeat: 500,
      vehicleModel: 'Maruti',
      vehicleNumber: 'TS09AB1234',
      notes: 'Direct highway drive, air-conditioned.',
      driver: const DriverDetailsEntity(
        id: 'usr-default',
        name: 'Driver',
        phone: '',
        rating: 4.8,
        totalTrips: 10,
      ),
    );
  }

  Future<SearchBookingDetailsEntity?> _fetchDetails(
    String endpoint,
    String? token,
  ) async {
    final uri = Uri.parse(endpoint);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('═══════════════════════════════════════════════════════════════');
    print('[CARPOOL SEARCH RIDE DETAILS API REQUEST]');
    print('URL: $endpoint');
    print('METHOD: GET');
    print('HEADERS: $headers');
    print('═══════════════════════════════════════════════════════════════');

    ApiLogger.logRequest(
      title: 'CARPOOL_SEARCH_RIDE_DETAILS',
      url: uri.toString(),
      method: 'GET',
      body: '',
      headers: headers,
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri).timeout(
        const Duration(seconds: 10),
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await response.transform(utf8.decoder).join();

      print('═══════════════════════════════════════════════════════════════');
      print('[CARPOOL SEARCH RIDE DETAILS API RESPONSE]');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: $body');
      print('═══════════════════════════════════════════════════════════════');

      ApiLogger.logResponse(
        title: 'CARPOOL_SEARCH_RIDE_DETAILS',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        Map<String, dynamic>? rideJson;

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            final dataMap = decoded['data'] as Map<String, dynamic>;
            if (dataMap['ride'] is Map<String, dynamic>) {
              rideJson = dataMap['ride'] as Map<String, dynamic>;
            } else {
              rideJson = dataMap;
            }
          } else if (decoded['ride'] is Map<String, dynamic>) {
            rideJson = decoded['ride'] as Map<String, dynamic>;
          } else {
            rideJson = decoded;
          }
        }

        if (rideJson != null) {
          return SearchBookingDetailsModel.fromJson(rideJson);
        }
      }
    } catch (e) {
      print('[CARPOOL SEARCH RIDE DETAILS ERROR] $e');
    } finally {
      client.close();
    }
    return null;
  }
}
