import '../core/constants/app_constants.dart';

enum MonitoringBand { typical, outsideTypical }

class HealthReading {
  const HealthReading({
    required this.id,
    required this.recordedAt,
    required this.heartRateBpm,
    required this.pulseRateBpm,
    required this.oxygenSaturation,
    required this.skinTemperatureCelsius,
    required this.sourceId,
    required this.sourceLabel,
    required this.isDemo,
  });

  final String id;
  final DateTime recordedAt;
  final int heartRateBpm;
  final int pulseRateBpm;
  final double oxygenSaturation;
  final double skinTemperatureCelsius;
  final String sourceId;
  final String sourceLabel;
  final bool isDemo;

  MonitoringBand get displayBand {
    final heartOk = heartRateBpm >= 55 && heartRateBpm <= 100;
    final pulseOk = pulseRateBpm >= 55 && pulseRateBpm <= 100;
    final oxygenOk = oxygenSaturation >= 95 && oxygenSaturation <= 100;
    final temperatureOk =
        skinTemperatureCelsius >= 31 && skinTemperatureCelsius <= 36.5;
    final inside = heartOk && pulseOk && oxygenOk && temperatureOk;
    return inside ? MonitoringBand.typical : MonitoringBand.outsideTypical;
  }

  String get statusTitle {
    if (!isDemo) {
      return displayBand == MonitoringBand.typical
          ? 'Sensor reading: typical display range'
          : 'Sensor reading: outside typical display range';
    }
    return displayBand == MonitoringBand.typical
        ? 'Typical display range'
        : 'Outside typical display range';
  }

  String get statusDetail => isDemo
      ? ''
      : 'This value came from a connected sensor. The app does not provide a diagnosis.';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordedAt': recordedAt.toIso8601String(),
      'heartRateBpm': heartRateBpm,
      'pulseRateBpm': pulseRateBpm,
      'oxygenSaturation': oxygenSaturation,
      'skinTemperatureCelsius': skinTemperatureCelsius,
      'sourceId': sourceId,
      'sourceLabel': sourceLabel,
      'isDemo': isDemo,
    };
  }

  factory HealthReading.fromJson(Map<String, dynamic> json) {
    final recorded = DateTime.tryParse('${json['recordedAt'] ?? ''}');
    if (recorded == null) {
      throw const FormatException('Missing scan time');
    }
    return HealthReading(
      id: json['id'] as String? ?? recorded.microsecondsSinceEpoch.toString(),
      recordedAt: recorded,
      heartRateBpm: (json['heartRateBpm'] as num).toInt(),
      pulseRateBpm: (json['pulseRateBpm'] as num).toInt(),
      oxygenSaturation: (json['oxygenSaturation'] as num).toDouble(),
      skinTemperatureCelsius: (json['skinTemperatureCelsius'] as num).toDouble(),
      sourceId: json['sourceId'] as String? ?? 'mock_sensor',
      sourceLabel: json['sourceLabel'] as String? ?? AppConstants.demoLabel,
      isDemo: json['isDemo'] as bool? ?? true,
    );
  }
}
