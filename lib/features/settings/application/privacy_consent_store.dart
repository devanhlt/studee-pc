import 'package:shared_preferences/shared_preferences.dart';

/// Tracks one-time DeepSeek privacy acknowledgment (local, non-secret).
class PrivacyConsentStore {
  PrivacyConsentStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _key = 'deepseek_privacy_acknowledged_v1';

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> isAcknowledged() async {
    final prefs = await _ensure();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> acknowledge() async {
    final prefs = await _ensure();
    await prefs.setBool(_key, true);
  }

  Future<void> resetForTests() async {
    final prefs = await _ensure();
    await prefs.remove(_key);
  }
}
