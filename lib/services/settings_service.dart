// lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _samplingIntervalKey = 'sampling_interval';
  static const String _themeColorKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode';

  Future<Duration> getSamplingInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final milliseconds = prefs.getInt(_samplingIntervalKey) ?? 500;
    return Duration(milliseconds: milliseconds);
  }

  Future<void> setSamplingInterval(Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_samplingIntervalKey, interval.inMilliseconds);
  }

  Future<Color> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_themeColorKey) ?? Colors.blue.value;
    return Color(colorValue);
  }

  Future<void> setThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.value);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? true; // Default to dark mode
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }
}
