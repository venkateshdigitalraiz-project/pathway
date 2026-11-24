import '../../domain/entities/carpool_settings_entity.dart';

class CarpoolSafetyAdvisoryModel extends CarpoolSafetyAdvisoryEntity {
  const CarpoolSafetyAdvisoryModel({
    required super.id,
    required super.title,
    required super.message,
    super.module = const [],
    super.platform = const [],
    super.targetModules = const [],
    super.placements = const [],
    super.severity = '',
  });

  factory CarpoolSafetyAdvisoryModel.fromJson(Map<String, dynamic> json) {
    return CarpoolSafetyAdvisoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      module: (json['module'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      platform:
          (json['platform'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      targetModules: (json['targetModules'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      placements:
          (json['placements'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      severity: json['severity']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'module': module,
        'platform': platform,
        'targetModules': targetModules,
        'placements': placements,
        'severity': severity,
      };
}

class CarpoolSettingsModel extends CarpoolSettingsEntity {
  const CarpoolSettingsModel({
    super.pricePerKm = 0.0,
    super.allowedDeviationPercent = 0,
    super.minAllowedDeviationPercent = 0,
    super.maxAllowedDeviationPercent = 0,
    super.platformCharge = 0,
    super.stopoverMultiplierPercent = 0,
    super.driverCommissionType = '',
    super.driverCommissionValue = 0,
    super.enableNegotiation = false,
    super.maxTwoInRear = false,
    super.ladiesOnlyFilter = false,
    super.instantBookingDefault = false,
    super.maxSeatsPerRide = 0,
    super.paymentOption = '',
    super.cancellationPolicy = '',
    super.passengerCancelFreeHours = 0,
    super.passengerCancelMidHours = 0,
    super.passengerCancelMidRefundPercent = 0,
    super.passengerCancelLastMinuteRefundPercent = 0,
    super.driverCancelRefundPercent = 0,
    super.safetyAdvisories = const [],
  });

  factory CarpoolSettingsModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map = json;
    if (map['data'] is Map<String, dynamic>) {
      map = map['data'] as Map<String, dynamic>;
    } else if (map['data'] is Map) {
      map = (map['data'] as Map).map((k, v) => MapEntry(k.toString(), v));
    }

    if (map['carpool'] is Map<String, dynamic>) {
      map = map['carpool'] as Map<String, dynamic>;
    } else if (map['carpool'] is Map) {
      map = (map['carpool'] as Map).map((k, v) => MapEntry(k.toString(), v));
    }

    final rawAdvisories = map['safetyAdvisories'] ?? map['advisories'];
    final List<CarpoolSafetyAdvisoryEntity> advisories = [];
    if (rawAdvisories is List) {
      for (final item in rawAdvisories) {
        if (item is Map<String, dynamic>) {
          advisories.add(CarpoolSafetyAdvisoryModel.fromJson(item));
        } else if (item is Map) {
          advisories.add(
            CarpoolSafetyAdvisoryModel.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }

    return CarpoolSettingsModel(
      pricePerKm: (map['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      allowedDeviationPercent:
          (map['allowedDeviationPercent'] as num?)?.toInt() ?? 0,
      minAllowedDeviationPercent:
          (map['minAllowedDeviationPercent'] as num?)?.toInt() ?? 0,
      maxAllowedDeviationPercent:
          (map['maxAllowedDeviationPercent'] as num?)?.toInt() ?? 0,
      platformCharge: (map['platformCharge'] as num?)?.toInt() ?? 0,
      stopoverMultiplierPercent:
          (map['stopoverMultiplierPercent'] as num?)?.toInt() ?? 0,
      driverCommissionType:
          map['driverCommissionType']?.toString() ?? '',
      driverCommissionValue:
          (map['driverCommissionValue'] as num?)?.toInt() ?? 0,
      enableNegotiation: map['enableNegotiation'] == true,
      maxTwoInRear: map['maxTwoInRear'] == true,
      ladiesOnlyFilter: map['ladiesOnlyFilter'] == true,
      instantBookingDefault: map['instantBookingDefault'] == true,
      maxSeatsPerRide: (map['maxSeatsPerRide'] as num?)?.toInt() ?? 0,
      paymentOption: map['paymentOption']?.toString() ?? '',
      cancellationPolicy: map['cancellationPolicy']?.toString() ?? '',
      passengerCancelFreeHours:
          (map['passengerCancelFreeHours'] as num?)?.toInt() ?? 0,
      passengerCancelMidHours:
          (map['passengerCancelMidHours'] as num?)?.toInt() ?? 0,
      passengerCancelMidRefundPercent:
          (map['passengerCancelMidRefundPercent'] as num?)?.toInt() ?? 0,
      passengerCancelLastMinuteRefundPercent:
          (map['passengerCancelLastMinuteRefundPercent'] as num?)?.toInt() ?? 0,
      driverCancelRefundPercent:
          (map['driverCancelRefundPercent'] as num?)?.toInt() ?? 0,
      safetyAdvisories: advisories,
    );
  }

  Map<String, dynamic> toJson() => {
        'pricePerKm': pricePerKm,
        'allowedDeviationPercent': allowedDeviationPercent,
        'minAllowedDeviationPercent': minAllowedDeviationPercent,
        'maxAllowedDeviationPercent': maxAllowedDeviationPercent,
        'platformCharge': platformCharge,
        'stopoverMultiplierPercent': stopoverMultiplierPercent,
        'driverCommissionType': driverCommissionType,
        'driverCommissionValue': driverCommissionValue,
        'enableNegotiation': enableNegotiation,
        'maxTwoInRear': maxTwoInRear,
        'ladiesOnlyFilter': ladiesOnlyFilter,
        'instantBookingDefault': instantBookingDefault,
        'maxSeatsPerRide': maxSeatsPerRide,
        'paymentOption': paymentOption,
        'cancellationPolicy': cancellationPolicy,
        'passengerCancelFreeHours': passengerCancelFreeHours,
        'passengerCancelMidHours': passengerCancelMidHours,
        'passengerCancelMidRefundPercent': passengerCancelMidRefundPercent,
        'passengerCancelLastMinuteRefundPercent':
            passengerCancelLastMinuteRefundPercent,
        'driverCancelRefundPercent': driverCancelRefundPercent,
        'safetyAdvisories': safetyAdvisories
            .map((a) => a is CarpoolSafetyAdvisoryModel
                ? a.toJson()
                : {
                    'id': a.id,
                    'title': a.title,
                    'message': a.message,
                    'module': a.module,
                    'platform': a.platform,
                    'targetModules': a.targetModules,
                    'placements': a.placements,
                    'severity': a.severity,
                  })
            .toList(),
      };
}
