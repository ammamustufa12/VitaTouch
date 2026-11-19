import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/health_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/shell_controller.dart';
import 'services/bluetooth_service.dart';
import 'services/health_api_client.dart';
import 'services/health_data_service.dart';
import 'services/local_health_store.dart';
import 'services/mock_sensor_service.dart';
import 'services/profile_store.dart';
import 'services/sensor_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await buildSmartHealthApp());
}

Future<Widget> buildSmartHealthApp({
  SharedPreferences? preferences,
  Widget? home,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final bluetooth = BluetoothService();
  final gateway = SensorGateway(
    demoSensor: MockSensorService(),
    bluetooth: bluetooth,
  );
  final health = HealthProvider(
    gateway: gateway,
    healthData: HealthDataService(
      store: LocalHealthStore(prefs),
      apiClient: const DisabledHealthApiClient(),
    ),
  );
  final profile = ProfileProvider(store: ProfileStore(prefs));

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BluetoothService>.value(value: bluetooth),
      ChangeNotifierProvider<ShellController>.value(value: ShellController()),
      ChangeNotifierProvider<HealthProvider>.value(value: health),
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      Provider<SensorGateway>.value(value: gateway),
    ],
    child: SmartHealthApp(home: home),
  );
}
