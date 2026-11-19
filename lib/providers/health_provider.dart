import 'package:flutter/foundation.dart';

import '../models/health_reading.dart';
import '../models/touch_signal.dart';
import '../services/health_api_client.dart';
import '../services/health_data_service.dart';
import '../services/sensor_gateway.dart';
import '../services/sensor_service.dart';
import '../services/storage_exception.dart';

class HealthProvider extends ChangeNotifier {
  HealthProvider({
    required this.gateway,
    required this.healthData,
  });

  final SensorGateway gateway;
  final HealthDataService healthData;

  bool loading = true;
  bool scanning = false;
  String? loadError;
  String? actionError;
  TouchSignal touch = TouchSignal.waiting;
  List<HealthReading> _readings = [];

  List<HealthReading> get readings => List.unmodifiable(_readings);
  HealthReading? get latest => _readings.isEmpty ? null : _readings.first;
  bool get usingDemoData => gateway.usingDemoData;

  Future<void> initialize() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      _readings = await healthData.load();
    } catch (_) {
      loadError = 'Saved demo scans could not be loaded.';
      _readings = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void noteTouch(TouchSignal signal) {
    touch = signal;
    notifyListeners();
  }

  Future<HealthReading> runScan(SensorCaptureRequest request) async {
    scanning = true;
    actionError = null;
    touch = TouchSignal.detected;
    notifyListeners();
    try {
      final reading = await gateway.active.capture(request);
      await healthData.save(reading);
      _readings = [
        reading,
        ..._readings.where((item) => item.id != reading.id),
      ];
      touch = TouchSignal.completed;
      return reading;
    } on ScanCancelled {
      touch = TouchSignal.interrupted;
      rethrow;
    } on StorageException catch (error) {
      actionError = error.message;
      touch = TouchSignal.interrupted;
      throw ScanFailed(error.message);
    } on HardwareNotLinkedException catch (error) {
      actionError = error.message;
      touch = TouchSignal.interrupted;
      throw ScanFailed(error.message);
    } catch (_) {
      actionError = 'The demo scan could not be completed.';
      touch = TouchSignal.interrupted;
      throw const ScanFailed('The demo scan could not be completed.');
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<RemoteSyncResult> sync() => healthData.sync();

  Future<void> clearHistory() async {
    actionError = null;
    notifyListeners();
    try {
      await healthData.clear();
      _readings = [];
      touch = TouchSignal.waiting;
    } on StorageException catch (error) {
      actionError = error.message;
    } finally {
      notifyListeners();
    }
  }
}
