import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
import '../../domain/entities/my_publish_ride_details_entity.dart';
import '../../domain/repositories/my_publish_ride_details_repository.dart';
import '../models/my_publish_ride_details_model.dart';

class MyPublishRideDetailsRepositoryImpl
    implements MyPublishRideDetailsRepository {
  static final MyPublishRideDetailsRepositoryImpl _instance =
      MyPublishRideDetailsRepositoryImpl._internal();

  factory MyPublishRideDetailsRepositoryImpl() => _instance;

  MyPublishRideDetailsRepositoryImpl._internal();

  @override
  Future<MyPublishRideDetailsEntity> getPublishRideDetails(String rideId) async {
    final endpoint = ApiEndpoints.rideDetails(rideId);
    final uri = Uri.parse(endpoint);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      ApiLogger.logRequest(
        title: 'GET_PUBLISH_RIDE_DETAILS',
        url: uri.toString(),
        method: 'GET',
        body: '',
        headers: headers,
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

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

      ApiLogger.logResponse(
        title: 'GET_PUBLISH_RIDE_DETAILS',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return MyPublishRideDetailsModel.fromJson(decoded);
        }
      } else {
        String errorMsg = 'Failed to load ride details (${response.statusCode})';
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['message'] != null) {
            errorMsg = decoded['message'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'GET_PUBLISH_RIDE_DETAILS',
        url: endpoint,
        error: e,
      );
      rethrow;
    }

    throw Exception('Unable to fetch ride details');
  }
}
