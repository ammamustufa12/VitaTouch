import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_monitor/models/health_reading.dart';
import 'package:smart_health_monitor/models/person_profile.dart';
import 'package:smart_health_monitor/services/bluetooth_service.dart';
import 'package:smart_health_monitor/services/mock_sensor_service.dart';
import 'package:smart_health_monitor/services/profile_store.dart';
import 'package:smart_health_monitor/services/sensor_gateway.dart';
import 'package:smart_health_monitor/services/sensor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mock sensor labels readings as demo data', () async {
    final reading = await MockSensorService(random: Random(4)).capture(
      SensorCaptureRequest(
        duration: Duration.zero,
        shouldContinue: () => true,
      ),
    );

    expect(reading.isDemo, isTrue);
    expect(reading.sourceLabel, 'DEMO DATA');
    expect(reading.heartRateBpm, inInclusiveRange(55, 100));
    expect(reading.displayBand, MonitoringBand.typical);
  });

  test('a lifted finger cancels the demo scan before it finishes', () async {
    final sensor = MockSensorService();
    await expectLater(
      sensor.capture(
        SensorCaptureRequest(
          duration: const Duration(seconds: 5),
          shouldContinue: () => false,
        ),
      ),
      throwsA(isA<ScanCancelled>()),
    );
  });

  test('gateway does not invent hardware readings', () async {
    final bluetooth = BluetoothService();
    final gateway = SensorGateway(
      demoSensor: MockSensorService(random: Random(1)),
      bluetooth: bluetooth,
    );

    expect(gateway.usingDemoData, isTrue);
    bluetooth.markLinkReady(deviceName: 'ESP32');
    expect(gateway.usingDemoData, isFalse);
    await expectLater(
      gateway.active.capture(
        SensorCaptureRequest(
          duration: Duration.zero,
          shouldContinue: () => true,
        ),
      ),
      throwsA(isA<HardwareNotLinkedException>()),
    );
  });

  test('profile stays empty until the user saves it', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = ProfileStore(preferences);
    final loaded = await store.load();

    expect(loaded.name, isEmpty);
    expect(loaded.dateOfBirth, isNull);
    expect(loaded.medicalHistory, isEmpty);
    expect(loaded.allergies, isEmpty);

    await store.save(
      const PersonProfile(
        name: 'Amina',
        gender: 'Female',
        bloodGroup: 'O+',
      ),
    );
    final again = await store.load();
    expect(again.name, 'Amina');
    expect(again.bloodGroup, 'O+');
    expect(again.allergies, isEmpty);
  });

  test('a hand-built reading can sit outside the display range', () {
    final reading = HealthReading(
      id: 'manual',
      recordedAt: DateTime.utc(2026, 1, 1),
      heartRateBpm: 140,
      pulseRateBpm: 140,
      oxygenSaturation: 99,
      skinTemperatureCelsius: 33,
      sourceId: 'mock_sensor',
      sourceLabel: 'DEMO DATA',
      isDemo: true,
    );
    expect(reading.displayBand, MonitoringBand.outsideTypical);
    expect(reading.statusTitle, contains('Demo status'));
  });
}
