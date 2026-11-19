import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/person_profile.dart';
import 'storage_exception.dart';

class ProfileStore {
  ProfileStore(this._preferences);

  final SharedPreferences _preferences;
  static const storageKey = 'person_profile_v1';

  Future<PersonProfile> load() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return PersonProfile.empty;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return PersonProfile.empty;
      }
      return PersonProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return PersonProfile.empty;
    }
  }

  Future<void> save(PersonProfile profile) async {
    final saved = await _preferences.setString(
      storageKey,
      jsonEncode(profile.toJson()),
    );
    if (!saved) {
      throw const StorageException(
        'The profile could not be saved on this device.',
      );
    }
  }
}
