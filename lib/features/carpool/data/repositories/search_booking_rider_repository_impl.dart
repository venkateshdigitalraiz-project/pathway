import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/repositories/search_booking_rider_repository.dart';
import '../models/carpool_models.dart';
import '../models/rider_booking_model.dart';

class SearchBookingRiderRepositoryImpl implements SearchBookingRiderRepository {
  static final SearchBookingRiderRepositoryImpl _instance =
      SearchBookingRiderRepositoryImpl._internal();
  factory SearchBookingRiderRepositoryImpl() => _instance;

  SearchBookingRiderRepositoryImpl._internal() {
    _bookings = [];
  }

  late final List<RiderBookingEntity> _bookings;

  @override
  Future<List<RiderBookingEntity>> getRiderBookings() async {
    // Attempt to fetch from API if available
    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/carpool/bookings/my',
        );
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 4));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        final response = await request.close().timeout(
          const Duration(seconds: 4),
        );
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final decoded = jsonDecode(body);
          List<dynamic> listJson = [];
          if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is List) listJson = decoded['data'] as List;
            if (decoded['data'] is Map && decoded['data']['bookings'] is List) {
              listJson = decoded['data']['bookings'] as List;
            }
          } else if (decoded is List) {
            listJson = decoded;
          }

          if (listJson.isNotEmpty) {
            final fetched = listJson
                .whereType<Map<String, dynamic>>()
                .map((j) => RiderBookingModel.fromJson(j))
                .toList();
            _bookings.clear();
            _bookings.addAll(fetched);
            return fetched;
          }
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));
    return [..._bookings]..sort((a, b) => b.departure.compareTo(a.departure));
  }

  @override
  Future<List<CarpoolRideEntity>> searchRides({
    required String from,
    required String to,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? date,
    int? seats,
    int? radiusKm,
  }) async {
    final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
      from,
      preferredLat: originLat,
      preferredLng: originLng,
      defaultLat: originLat ?? 0.0,
      defaultLng: originLng ?? 0.0,
    );
    final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
      to,
      preferredLat: destinationLat,
      preferredLng: destinationLng,
      defaultLat: destinationLat ?? 0.0,
      defaultLng: destinationLng ?? 0.0,
    );

    final resolvedOriginLat = originCoords.lat;
    final resolvedOriginLng = originCoords.lng;
    final resolvedDestLat = destCoords.lat;
    final resolvedDestLng = destCoords.lng;

    final resolvedDate = date ?? DateTime.now();
    final dateStr =
        '${resolvedDate.year.toString().padLeft(4, '0')}-${resolvedDate.month.toString().padLeft(2, '0')}-${resolvedDate.day.toString().padLeft(2, '0')}';
    final passengersCount = (seats != null && seats > 0) ? seats : 2;
    final resolvedRadius = radiusKm ?? 30;

    final targetUrl = ApiEndpoints.searchRides;
    final uri = Uri.parse(targetUrl);

    final requestBody = {
      'originLat': resolvedOriginLat,
      'originLng': resolvedOriginLng,
      'destinationLat': resolvedDestLat,
      'destinationLng': resolvedDestLng,
      'date': dateStr,
      'passengers': passengersCount,
      'radiusKm': resolvedRadius,
    };
    final payloadJson = jsonEncode(requestBody);

    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Authorization header commented out as requested
        // if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      ApiLogger.logRequest(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        method: 'POST',
        body: payloadJson,
        headers: headers,
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // Authorization header commented out as requested
      // if (token != null && token.isNotEmpty) {
      //   request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      // }
      request.write(payloadJson);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);
        List<dynamic> listJson = [];
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic> &&
              decoded['data']['rides'] is List) {
            listJson = decoded['data']['rides'] as List;
          } else if (decoded['data'] is List) {
            listJson = decoded['data'] as List;
          } else if (decoded['rides'] is List) {
            listJson = decoded['rides'] as List;
          }
        } else if (decoded is List) {
          listJson = decoded;
        }

        final results = listJson
            .whereType<Map<String, dynamic>>()
            .map((j) => CarpoolRideModel.fromJson(j))
            .toList();
        return results;
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        error: e,
      );
    }

    return [];
  }

  @override
  Future<RiderBookingEntity> bookSeat({
    required CarpoolRideEntity ride,
    required int seats,
    String? pickupPoint,
    String? dropoffPoint,
    String? passengerNotes,
  }) async {
    final targetUrl = ApiEndpoints.bookRide(ride.id);

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

      final payloadMap = <String, dynamic>{
        'seatsBooked': seats,
        'pickupPoint': (pickupPoint != null && pickupPoint.trim().isNotEmpty)
            ? pickupPoint.trim()
            : ride.from,
        'dropoffPoint': (dropoffPoint != null && dropoffPoint.trim().isNotEmpty)
            ? dropoffPoint.trim()
            : ride.to,
        if (passengerNotes != null && passengerNotes.trim().isNotEmpty)
          'passengerNotes': passengerNotes.trim(),
      };
      final payloadJson = jsonEncode(payloadMap);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (cleanToken != null && cleanToken.isNotEmpty)
          'Authorization': 'Bearer $cleanToken',
      };

      ApiLogger.logRequest(
        title: 'BOOK_CARPOOL_RIDE',
        method: 'POST',
        url: targetUrl,
        headers: headers,
        body: payloadJson,
      );

      final uri = Uri.parse(targetUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client
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
      request.write(payloadJson);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'BOOK_CARPOOL_RIDE',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic>? bookingData;
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is Map<String, dynamic>) {
              final d = decoded['data'] as Map<String, dynamic>;
              if (d['booking'] is Map<String, dynamic>) {
                bookingData = d['booking'] as Map<String, dynamic>;
              } else {
                bookingData = d;
              }
            } else if (decoded['booking'] is Map<String, dynamic>) {
              bookingData = decoded['booking'] as Map<String, dynamic>;
            } else {
              bookingData = decoded;
            }
          }
        } catch (_) {}

        final newBooking = RiderBookingModel(
          id:
              bookingData?['id']?.toString() ??
              bookingData?['_id']?.toString() ??
              'bk-${DateTime.now().millisecondsSinceEpoch % 10000}',
          rideId: bookingData?['rideId']?.toString() ?? ride.id,
          driverName:
              bookingData?['driverName']?.toString() ??
              (bookingData?['driver'] is Map
                  ? (bookingData!['driver']['name']?.toString() ??
                        ride.driverName)
                  : ride.driverName),
          driverPhone:
              bookingData?['driverPhone']?.toString() ??
              (bookingData?['driver'] is Map
                  ? (bookingData!['driver']['phone']?.toString() ??
                        '+91 98765 12340')
                  : '+91 98765 12340'),
          driverRating:
              (bookingData?['driverRating'] as num?)?.toDouble() ??
              (bookingData?['driver'] is Map
                  ? ((bookingData!['driver']['rating'] as num?)?.toDouble() ??
                        ride.driverRating)
                  : ride.driverRating),
          vehicle:
              bookingData?['vehicle']?.toString() ??
              bookingData?['vehicleModel']?.toString() ??
              ride.vehicle,
          vehicleNumber:
              bookingData?['vehicleNumber']?.toString() ??
              ride.vehicleNumber ??
              'Verified Car',
          from: (pickupPoint != null && pickupPoint.trim().isNotEmpty)
              ? pickupPoint.trim()
              : (bookingData?['from']?.toString() ??
                    bookingData?['pickupPoint']?.toString() ??
                    ride.from),
          to: (dropoffPoint != null && dropoffPoint.trim().isNotEmpty)
              ? dropoffPoint.trim()
              : (bookingData?['to']?.toString() ??
                    bookingData?['dropoffPoint']?.toString() ??
                    ride.to),
          departure: ride.departure,
          seatsBooked: (bookingData?['seatsBooked'] as num?)?.toInt() ?? seats,
          pricePerSeat:
              (bookingData?['pricePerSeat'] as num?)?.toInt() ??
              ride.pricePerSeat,
          totalAmount:
              (bookingData?['totalAmount'] as num?)?.toInt() ??
              (ride.pricePerSeat * seats),
          status: RiderBookingStatus.confirmed,
          bookingDate: DateTime.now(),
          otpCode:
              bookingData?['otpCode']?.toString() ??
              bookingData?['otp']?.toString() ??
              '${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}',
          passengerNotes:
              passengerNotes ?? bookingData?['passengerNotes']?.toString(),
        );

        _bookings.insert(0, newBooking);
        return newBooking;
      } else {
        String errorMsg = 'Booking failed (${response.statusCode})';
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            errorMsg = decoded['message'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ApiLogger.logError(title: 'BOOK_CARPOOL_RIDE', url: targetUrl, error: e);
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        status: RiderBookingStatus.cancelled,
      );
    }
  }
}
