import 'dart:convert';
import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
import '../models/carpool_settings_model.dart';

abstract class CarpoolSettingsRemoteDataSource {
  Future<CarpoolSettingsModel> getCarpoolSettings();
}

class CarpoolSettingsRemoteDataSourceImpl
    implements CarpoolSettingsRemoteDataSource {
  final AuthLocalStorage _authStorage;

  CarpoolSettingsRemoteDataSourceImpl({AuthLocalStorage? authStorage})
      : _authStorage = authStorage ?? AuthLocalStorage();

  @override
  Future<CarpoolSettingsModel> getCarpoolSettings() async {
    const url = ApiEndpoints.carpoolSettings;
    final uri = Uri.parse(url);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = await _authStorage.getAccessTokenAsync() ??
        _authStorage.getToken() ??
        '';
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    ApiLogger.logRequest(
      title: 'GET_CARPOOL_SETTINGS',
      url: url,
      method: 'GET',
      body: '',
      headers: headers,
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 8),
          );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close().timeout(
            const Duration(seconds: 8),
          );
      final body = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'GET_CARPOOL_SETTINGS',
        url: url,
        statusCode: response.statusCode,
        responseBody: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return CarpoolSettingsModel.fromJson(decoded);
        } else if (decoded is Map) {
          return CarpoolSettingsModel.fromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
      throw HttpException(
        'Failed to load carpool settings (HTTP ${response.statusCode})',
        uri: uri,
      );
    } catch (e) {
      ApiLogger.logError(
        title: 'GET_CARPOOL_SETTINGS',
        url: url,
        error: e,
      );
      rethrow;
    } finally {
      client.close();
    }
  }
}
