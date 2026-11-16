import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/repositories/my_ride_booking_repository.dart';
import '../models/rider_booking_model.dart';

class MyRideBookingRepositoryImpl implements MyRideBookingRepository {
  static final MyRideBookingRepositoryImpl _instance =
      MyRideBookingRepositoryImpl._internal();
  factory MyRideBookingRepositoryImpl() => _instance;

  MyRideBookingRepositoryImpl._internal();

  final List<RiderBookingEntity> _bookings = [];

  @override
  Future<List<RiderBookingEntity>> getMyRideBookings() async {
    final targetUrl = ApiEndpoints.myBookings;

    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      String? cleanToken;
      if (token != null && token.isNotEmpty) {
        String t = token.trim();
        while (t.toLowerCase().startsWith('bearer ')) {
          t = t.substring(7).trim();
        }
        cleanToken = t.isNotEmpty ? t : null;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (cleanToken != null && cleanToken.isNotEmpty)
          'Authorization': 'Bearer $cleanToken',
      };

      ApiLogger.logRequest(
        title: 'GET_MY_RIDE_BOOKINGS',
        method: 'GET',
        url: targetUrl,
        headers: headers,
        body: '',
      );

      final uri = Uri.parse(targetUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (cleanToken != null && cleanToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $cleanToken',
        );
      }

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'GET_MY_RIDE_BOOKINGS',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);
        List<dynamic> listJson = [];
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            listJson = decoded['data'] as List;
          } else if (decoded['data'] is Map &&
              decoded['data']['bookings'] is List) {
            listJson = decoded['data']['bookings'] as List;
          } else if (decoded['bookings'] is List) {
            listJson = decoded['bookings'] as List;
          }
        } else if (decoded is List) {
          listJson = decoded;
        }

        final fetched = listJson
            .whereType<Map<String, dynamic>>()
            .map((j) => RiderBookingModel.fromJson(j))
            .toList();

        _bookings.clear();
        _bookings.addAll(fetched);
        return fetched;
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'GET_MY_RIDE_BOOKINGS',
        url: targetUrl,
        error: e,
      );
    }

    return [..._bookings]..sort((a, b) => b.departure.compareTo(a.departure));
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final targetUrl = ApiEndpoints.cancelBooking(bookingId);
    final fallbackUrl = ApiEndpoints.cancelRide(bookingId);

    final storage = AuthLocalStorage();
    await storage.init();
    final token = await storage.getAccessTokenAsync();

    String? cleanToken;
    if (token != null && token.isNotEmpty) {
      String t = token.trim();
      while (t.toLowerCase().startsWith('bearer ')) {
        t = t.substring(7).trim();
      }
      cleanToken = t.isNotEmpty ? t : null;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (cleanToken != null && cleanToken.isNotEmpty)
        'Authorization': 'Bearer $cleanToken',
    };

    final bodyMap = <String, dynamic>{
      'reason': reason ?? 'Travel plans changed',
    };
    final bodyJson = jsonEncode(bodyMap);

    ApiLogger.logRequest(
      title: 'CANCEL_RIDE_BOOKING',
      method: 'POST',
      url: targetUrl,
      headers: headers,
      body: bodyJson,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      var uri = Uri.parse(targetUrl);

      var request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (cleanToken != null && cleanToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $cleanToken',
        );
      }
      request.write(bodyJson);

      var response = await request.close().timeout(const Duration(seconds: 10));
      var responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'CANCEL_RIDE_BOOKING',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      // If 404, fallback to cancelRide endpoint
      if (response.statusCode == 404) {
        uri = Uri.parse(fallbackUrl);
        request = await client
            .postUrl(uri)
            .timeout(const Duration(seconds: 10));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (cleanToken != null && cleanToken.isNotEmpty) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $cleanToken',
          );
        }
        request.write(bodyJson);
        response = await request.close().timeout(const Duration(seconds: 10));
        responseBody = await response.transform(utf8.decoder).join();
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'CANCEL_RIDE_BOOKING',
        url: targetUrl,
        error: e,
      );
    }

    // Update locally
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        status: RiderBookingStatus.cancelled,
      );
    }
  }
}
