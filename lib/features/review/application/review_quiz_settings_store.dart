import 'package:shared_preferences/shared_preferences.dart';
import 'package:studee_pc/features/review/application/review_quiz_config.dart';

/// Persists the user's Ôn tập exam duration preference.
class ReviewQuizSettingsStore {
  ReviewQuizSettingsStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _durationMinutesKey = 'review_quiz_duration_minutes';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<int> loadDurationMinutes() async {
    final prefs = await _ensure();
    return ReviewQuizConfig.snapDurationMinutes(
      prefs.getInt(_durationMinutesKey) ??
          ReviewQuizConfig.defaultDurationMinutes,
    );
  }

  Future<Duration> loadDuration() async {
    return Duration(minutes: await loadDurationMinutes());
  }

  Future<void> setDurationMinutes(int minutes) async {
    final prefs = await _ensure();
    await prefs.setInt(
      _durationMinutesKey,
      ReviewQuizConfig.snapDurationMinutes(minutes),
    );
  }
}
