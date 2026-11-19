import 'bluetooth_service.dart';
import 'sensor_service.dart';

/// Chooses the sensor implementation without involving widgets.
///
/// [active] stays on the demo sensor until a Bluetooth link is marked ready.
/// Register a real driver with [useHardwareDriver] when ESP32 support lands.
class SensorGateway {
  SensorGateway({
    required SensorService demoSensor,
    required BluetoothService bluetooth,
  })  : _demoSensor = demoSensor,
        _bluetooth = bluetooth,
        _hardwareSensor = BluetoothSensorService(bluetooth);

  final SensorService _demoSensor;
  final BluetoothService _bluetooth;
  SensorService _hardwareSensor;

  SensorService get active {
    if (_bluetooth.isReadyForReadings) {
      return _hardwareSensor;
    }
    return _demoSensor;
  }

  bool get usingDemoData => active.producesDemoData;

  void useHardwareDriver(SensorService driver) {
    _hardwareSensor = driver;
  }
}
