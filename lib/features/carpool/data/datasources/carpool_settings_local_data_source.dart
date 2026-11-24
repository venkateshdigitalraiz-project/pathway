import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/carpool_settings_entity.dart';
import '../models/carpool_settings_model.dart';

/// Singleton & Data Source for persisting Carpool Settings in SharedPreferences
/// and providing synchronous global access (`CarpoolSettingsStorage.current`).
class CarpoolSettingsLocalDataSource {
  static final CarpoolSettingsLocalDataSource _instance =
      CarpoolSettingsLocalDataSource._internal();

  factory CarpoolSettingsLocalDataSource() => _instance;

  CarpoolSettingsLocalDataSource._internal();

  static const String keyCarpoolSettings = 'carpool_settings_json';

  SharedPreferences? _prefs;
  CarpoolSettingsEntity _current = CarpoolSettingsEntity.defaultSettings;

  /// Global synchronous access to the currently cached Carpool Settings across all classes
  static CarpoolSettingsEntity get current => _instance._current;

  /// SharedPreferences instance
  SharedPreferences? get preferences => _prefs;

  /// Initializes SharedPreferences and loads cached settings into memory
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(keyCarpoolSettings);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _current = CarpoolSettingsModel.fromJson(decoded);
        } else if (decoded is Map) {
          _current = CarpoolSettingsModel.fromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    } catch (e) {
      debugPrint('[CarpoolSettingsLocalDataSource] Error initializing cache: $e');
    }
  }

  /// Returns cached settings (in-memory)
  CarpoolSettingsEntity getSettings() {
    return _current;
  }

  /// Persists settings to SharedPreferences and updates in-memory cache
  Future<void> saveSettings(CarpoolSettingsEntity settings) async {
    _current = settings;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final model = settings is CarpoolSettingsModel
          ? settings
          : CarpoolSettingsModel(
              pricePerKm: settings.pricePerKm,
              allowedDeviationPercent: settings.allowedDeviationPercent,
              minAllowedDeviationPercent: settings.minAllowedDeviationPercent,
              maxAllowedDeviationPercent: settings.maxAllowedDeviationPercent,
              platformCharge: settings.platformCharge,
              stopoverMultiplierPercent: settings.stopoverMultiplierPercent,
              driverCommissionType: settings.driverCommissionType,
              driverCommissionValue: settings.driverCommissionValue,
              enableNegotiation: settings.enableNegotiation,
              maxTwoInRear: settings.maxTwoInRear,
              ladiesOnlyFilter: settings.ladiesOnlyFilter,
              instantBookingDefault: settings.instantBookingDefault,
              maxSeatsPerRide: settings.maxSeatsPerRide,
              paymentOption: settings.paymentOption,
              cancellationPolicy: settings.cancellationPolicy,
              passengerCancelFreeHours: settings.passengerCancelFreeHours,
              passengerCancelMidHours: settings.passengerCancelMidHours,
              passengerCancelMidRefundPercent:
                  settings.passengerCancelMidRefundPercent,
              passengerCancelLastMinuteRefundPercent:
                  settings.passengerCancelLastMinuteRefundPercent,
              driverCancelRefundPercent: settings.driverCancelRefundPercent,
              safetyAdvisories: settings.safetyAdvisories,
            );

      final jsonStr = jsonEncode(model.toJson());
      await _prefs?.setString(keyCarpoolSettings, jsonStr);

      debugPrint('\n════════════ [LOCAL STORAGE: CARPOOL SETTINGS SAVED] ════════════');
      debugPrint('PRICE_PER_KM: ₹${settings.pricePerKm}');
      debugPrint('MAX_SEATS_PER_RIDE: ${settings.maxSeatsPerRide}');
      debugPrint('ALLOWED_DEVIATION: ${settings.allowedDeviationPercent}%');
      debugPrint('SAFETY_ADVISORIES: ${settings.safetyAdvisories.length}');
      debugPrint('═══════════════════════════════════════════════════════════════════\n');
    } catch (e) {
      debugPrint('[CarpoolSettingsLocalDataSource] Error saving settings: $e');
    }
  }

  /// Clears stored carpool settings
  Future<void> clearSettings() async {
    _current = CarpoolSettingsEntity.defaultSettings;
    await _prefs?.remove(keyCarpoolSettings);
  }
}

/// Shorthand alias to easily access carpool settings from ANY class
typedef CarpoolSettingsStorage = CarpoolSettingsLocalDataSource;
