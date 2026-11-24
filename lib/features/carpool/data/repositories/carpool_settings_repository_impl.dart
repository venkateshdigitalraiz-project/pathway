import 'package:flutter/foundation.dart';
import '../../domain/entities/carpool_settings_entity.dart';
import '../../domain/repositories/carpool_settings_repository.dart';
import '../datasources/carpool_settings_local_data_source.dart';
import '../datasources/carpool_settings_remote_data_source.dart';

class CarpoolSettingsRepositoryImpl implements CarpoolSettingsRepository {
  final CarpoolSettingsRemoteDataSource remoteDataSource;
  final CarpoolSettingsLocalDataSource localDataSource;

  CarpoolSettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<CarpoolSettingsEntity> getCarpoolSettings({
    bool forceRefresh = false,
  }) async {
    // 1. If not forcing refresh, check if local storage already has non-default settings
    if (!forceRefresh) {
      final cached = localDataSource.getSettings();
      // If we already loaded cached settings from shared_preferences, we can use them
      // but still fetch in the background or attempt network fetch
    }

    // 2. Fetch from remote API
    try {
      final remoteSettings = await remoteDataSource.getCarpoolSettings();
      // 3. Persist into SharedPreferences & in-memory cache
      await localDataSource.saveSettings(remoteSettings);
      return remoteSettings;
    } catch (e) {
      debugPrint('[CarpoolSettingsRepositoryImpl] Remote fetch failed ($e). Using cached.');
      // 4. Return cached settings on network error
      return localDataSource.getSettings();
    }
  }

  @override
  CarpoolSettingsEntity getCachedSettings() {
    return localDataSource.getSettings();
  }
}
