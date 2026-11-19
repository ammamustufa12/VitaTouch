import 'dart:math';

import '../core/constants/app_constants.dart';
import '../models/health_reading.dart';
import 'sensor_service.dart';

class MockSensorService implements SensorService {
  MockSensorService({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  String get id => 'mock_sensor';

  @override
  String get displayName => 'Simulated sensor';

  @override
  bool get producesDemoData => true;

  @override
  Future<HealthReading> capture(SensorCaptureRequest request) async {
    final totalMs = max(0, request.duration.inMilliseconds);
    if (totalMs == 0) {
      if (!request.shouldContinue()) {
        throw const ScanCancelled();
      }
      request.onProgress?.call(1);
      return _nextReading();
    }

    final ticks = max(1, totalMs ~/ 100);
    final sliceMs = max(1, totalMs ~/ ticks);
    for (var step = 1; step <= ticks; step++) {
      if (!request.shouldContinue()) {
        throw const ScanCancelled();
      }
      await Future<void>.delayed(Duration(milliseconds: sliceMs));
      if (!request.shouldContinue()) {
        throw const ScanCancelled();
      }
      request.onProgress?.call(step / ticks);
    }
    return _nextReading();
  }

  HealthReading _nextReading() {
    final heartRate = 64 + _random.nextInt(26);
    final pulseDelta = _random.nextInt(3) - 1;
    final oxygen = 96 + (_random.nextInt(31) / 10);
    final temperature = (320 + _random.nextInt(31)) / 10;
    final now = DateTime.now();
    return HealthReading(
      id: now.microsecondsSinceEpoch.toString(),
      recordedAt: now,
      heartRateBpm: heartRate,
      pulseRateBpm: max(55, heartRate + pulseDelta),
      oxygenSaturation: double.parse(oxygen.toStringAsFixed(1)),
      skinTemperatureCelsius: temperature,
      sourceId: id,
      sourceLabel: AppConstants.demoLabel,
      isDemo: true,
    );
  }
}
