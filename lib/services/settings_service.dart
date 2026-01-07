// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _samplingIntervalKey = 'sampling_interval';

  Future<Duration> getSamplingInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final milliseconds = prefs.getInt(_samplingIntervalKey) ?? 500;
    return Duration(milliseconds: milliseconds);
  }

  Future<void> setSamplingInterval(Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_samplingIntervalKey, interval.inMilliseconds);
  }
}
