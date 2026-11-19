import '../models/health_reading.dart';

class SensorCaptureRequest {
  const SensorCaptureRequest({
    required this.duration,
    required this.shouldContinue,
    this.onProgress,
  });

  final Duration duration;
  final bool Function() shouldContinue;
  final void Function(double progress)? onProgress;
}

class ScanCancelled implements Exception {
  const ScanCancelled();
}

class ScanFailed implements Exception {
  const ScanFailed(this.message);

  final String message;
}

class HardwareNotLinkedException implements Exception {
  const HardwareNotLinkedException([
    this.message = 'No ESP32 / MAX30102 device is connected.',
  ]);

  final String message;
}

/// Contract used by the scan screen. UI code depends on this type,
/// not on a mock or a Bluetooth driver.
abstract class SensorService {
  String get id;
  String get displayName;
  bool get producesDemoData;

  Future<HealthReading> capture(SensorCaptureRequest request);
}
