import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this phone does in the broadcast.
enum PhoneRole {
  camera,
  director,
  both,
}

/// Global app state. Saved to disk so the phone remembers its role.
class AppSettings extends ChangeNotifier {
  static const _kRole = 'phone_role';

  PhoneRole? _role;
  PhoneRole? get role => _role;

  /// Load saved settings from disk. Call once on startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kRole);
    if (saved != null) {
      _role = PhoneRole.values.firstWhere(
        (r) => r.name == saved,
        orElse: () => PhoneRole.director,
      );
    }
    notifyListeners();
  }

  Future<void> setRole(PhoneRole role) async {
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, role.name);
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRole);
    notifyListeners();
  }
}
