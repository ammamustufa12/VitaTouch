import 'package:flutter/foundation.dart';

import '../models/health_reading.dart';
import 'sensor_service.dart';

enum BluetoothLinkPhase { notConfigured, checking, hardwareUnavailable, ready }

/// Bluetooth transport for a future ESP32 that forwards MAX30102 samples.
///
/// This class does not open a radio and does not invent measurements.
/// A later driver can call [markLinkReady] only after a real device link,
/// then replace [BluetoothSensorService.capture] with characteristic reads.
class BluetoothService extends ChangeNotifier {
  BluetoothLinkPhase phase = BluetoothLinkPhase.notConfigured;
  String? lastDeviceName;
  String detail =
      'No external sensor is connected. Readings on this phone are simulated demo data.';

  bool get isReadyForReadings => phase == BluetoothLinkPhase.ready;

  Future<void> checkForHardware() async {
    phase = BluetoothLinkPhase.checking;
    detail = 'Looking for a Bluetooth health sensor…';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    phase = BluetoothLinkPhase.hardwareUnavailable;
    lastDeviceName = null;
    detail =
        'ESP32 / MAX30102 is not connected. BluetoothService is ready for a driver. Scans stay on demo data.';
    notifyListeners();
  }

  /// Reserved for a real driver. Do not call this from the UI.
  void markLinkReady({required String deviceName}) {
    phase = BluetoothLinkPhase.ready;
    lastDeviceName = deviceName;
    detail = 'Connected to $deviceName.';
    notifyListeners();
  }
}

class BluetoothSensorService implements SensorService {
  BluetoothSensorService(this.bluetooth);

  final BluetoothService bluetooth;

  @override
  String get id => 'esp32_max30102';

  @override
  String get displayName => 'ESP32 / MAX30102';

  @override
  bool get producesDemoData => false;

  @override
  Future<HealthReading> capture(SensorCaptureRequest request) async {
    if (!bluetooth.isReadyForReadings) {
      throw const HardwareNotLinkedException();
    }
    throw const HardwareNotLinkedException(
      'The Bluetooth driver is not implemented yet, so no sensor reading was created.',
    );
  }
}
