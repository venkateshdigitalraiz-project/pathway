import 'package:equatable/equatable.dart';

/// Single safety advisory note for carpool module
class CarpoolSafetyAdvisoryEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final List<String> module;
  final List<String> platform;
  final List<String> targetModules;
  final List<String> placements;
  final String severity;

  const CarpoolSafetyAdvisoryEntity({
    required this.id,
    required this.title,
    required this.message,
    this.module = const [],
    this.platform = const [],
    this.targetModules = const [],
    this.placements = const [],
    this.severity = '',
  });

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        module,
        platform,
        targetModules,
        placements,
        severity,
      ];
}

/// Carpool Settings Entity (matching /api/settings/carpool response)
class CarpoolSettingsEntity extends Equatable {
  final double pricePerKm;
  final int allowedDeviationPercent;
  final int minAllowedDeviationPercent;
  final int maxAllowedDeviationPercent;
  final int platformCharge;
  final int stopoverMultiplierPercent;
  final String driverCommissionType;
  final int driverCommissionValue;
  final bool enableNegotiation;
  final bool maxTwoInRear;
  final bool ladiesOnlyFilter;
  final bool instantBookingDefault;
  final int maxSeatsPerRide;
  final String paymentOption;
  final String cancellationPolicy;
  final int passengerCancelFreeHours;
  final int passengerCancelMidHours;
  final int passengerCancelMidRefundPercent;
  final int passengerCancelLastMinuteRefundPercent;
  final int driverCancelRefundPercent;
  final List<CarpoolSafetyAdvisoryEntity> safetyAdvisories;

  const CarpoolSettingsEntity({
    this.pricePerKm = 0.0,
    this.allowedDeviationPercent = 0,
    this.minAllowedDeviationPercent = 0,
    this.maxAllowedDeviationPercent = 0,
    this.platformCharge = 0,
    this.stopoverMultiplierPercent = 0,
    this.driverCommissionType = '',
    this.driverCommissionValue = 0,
    this.enableNegotiation = false,
    this.maxTwoInRear = false,
    this.ladiesOnlyFilter = false,
    this.instantBookingDefault = false,
    this.maxSeatsPerRide = 0,
    this.paymentOption = '',
    this.cancellationPolicy = '',
    this.passengerCancelFreeHours = 0,
    this.passengerCancelMidHours = 0,
    this.passengerCancelMidRefundPercent = 0,
    this.passengerCancelLastMinuteRefundPercent = 0,
    this.driverCancelRefundPercent = 0,
    this.safetyAdvisories = const [],
  });

  /// Empty settings instance (all dynamic fields initialized cleanly)
  static const CarpoolSettingsEntity empty = CarpoolSettingsEntity();
  static const CarpoolSettingsEntity defaultSettings = empty;

  @override
  List<Object?> get props => [
        pricePerKm,
        allowedDeviationPercent,
        minAllowedDeviationPercent,
        maxAllowedDeviationPercent,
        platformCharge,
        stopoverMultiplierPercent,
        driverCommissionType,
        driverCommissionValue,
        enableNegotiation,
        maxTwoInRear,
        ladiesOnlyFilter,
        instantBookingDefault,
        maxSeatsPerRide,
        paymentOption,
        cancellationPolicy,
        passengerCancelFreeHours,
        passengerCancelMidHours,
        passengerCancelMidRefundPercent,
        passengerCancelLastMinuteRefundPercent,
        driverCancelRefundPercent,
        safetyAdvisories,
      ];
}
