import '../models/health_reading.dart';
import 'health_api_client.dart';
import 'local_health_store.dart';

class HealthDataService {
  HealthDataService({
    required this.store,
    required this.apiClient,
  });

  final LocalHealthStore store;
  final HealthApiClient apiClient;

  Future<List<HealthReading>> load() => store.loadAll();

  Future<void> save(HealthReading reading) async {
    final existing = await store.loadAll();
    final next = [
      reading,
      ...existing.where((item) => item.id != reading.id),
    ];
    await store.saveAll(next);
  }

  Future<void> clear() => store.saveAll(const []);

  Future<RemoteSyncResult> sync() async {
    final readings = await store.loadAll();
    return apiClient.uploadReadings(readings);
  }
}
