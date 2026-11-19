import '../models/health_reading.dart';

class RemoteSyncResult {
  const RemoteSyncResult({
    required this.configured,
    required this.message,
  });

  final bool configured;
  final String message;
}

abstract class HealthApiClient {
  Future<RemoteSyncResult> uploadReadings(List<HealthReading> readings);
}

class DisabledHealthApiClient implements HealthApiClient {
  const DisabledHealthApiClient();

  @override
  Future<RemoteSyncResult> uploadReadings(List<HealthReading> readings) async {
    final count = readings.length;
    final message = count == 0
        ? 'REST API is not configured. There are no demo scans to send.'
        : 'REST API is not configured. $count demo scan${count == 1 ? '' : 's'} stay on this device.';
    return RemoteSyncResult(configured: false, message: message);
  }
}
