import 'package:flutter/foundation.dart';

import '../models/person_profile.dart';
import '../services/profile_store.dart';
import '../services/storage_exception.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this.store});

  final ProfileStore store;

  bool loading = true;
  bool saving = false;
  String? error;
  PersonProfile profile = PersonProfile.empty;

  Future<void> initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await store.load();
    } catch (_) {
      error = 'The profile could not be loaded.';
      profile = PersonProfile.empty;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(PersonProfile value) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await store.save(value);
      profile = value;
      return true;
    } on StorageException catch (caught) {
      error = caught.message;
      return false;
    } catch (_) {
      error = 'The profile could not be saved on this device.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> clear() => save(PersonProfile.empty);
}
