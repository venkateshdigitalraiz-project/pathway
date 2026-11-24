import '../entities/carpool_settings_entity.dart';

abstract class CarpoolSettingsRepository {
  /// Fetches carpool settings from backend API and saves them to local SharedPreferences.
  /// If offline or request fails, returns cached settings from SharedPreferences.
  Future<CarpoolSettingsEntity> getCarpoolSettings({bool forceRefresh = false});

  /// Synchronous/cached access to locally stored carpool settings.
  CarpoolSettingsEntity getCachedSettings();
}
