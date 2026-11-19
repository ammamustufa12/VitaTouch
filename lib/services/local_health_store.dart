import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_reading.dart';
import 'storage_exception.dart';

class LocalHealthStore {
  LocalHealthStore(this._preferences);

  final SharedPreferences _preferences;
  static const storageKey = 'demo_health_readings_v1';
  static const maxRecords = 40;

  Future<List<HealthReading>> loadAll() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      final readings = <HealthReading>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        try {
          readings.add(
            HealthReading.fromJson(Map<String, dynamic>.from(item)),
          );
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      readings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return readings;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<HealthReading> readings) async {
    final trimmed = readings.take(maxRecords).toList();
    final encoded = jsonEncode(
      trimmed.map((reading) => reading.toJson()).toList(),
    );
    final saved = await _preferences.setString(storageKey, encoded);
    if (!saved) {
      throw const StorageException(
        'Demo scans could not be saved on this device.',
      );
    }
  }
}
