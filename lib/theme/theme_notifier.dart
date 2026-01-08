// lib/theme/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:autoperf_monitor/services/settings_service.dart';

class ThemeNotifier with ChangeNotifier {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) {
    _loadSettings();
  }

  bool _isDarkMode = true;
  Color _primaryColor = Colors.blue;
  ThemeData? _themeData;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  ThemeData get getTheme => _themeData ?? (_isDarkMode ? darkTheme : lightTheme);

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  void _loadSettings() async {
    _isDarkMode = await _settingsService.getDarkMode();
    _primaryColor = await _settingsService.getThemeColor();
    _themeData = _isDarkMode ? darkTheme : lightTheme;
    notifyListeners();
  }

  void setDarkMode(bool value) async {
    _isDarkMode = value;
    _themeData = _isDarkMode ? darkTheme : lightTheme;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void setPrimaryColor(Color color) async {
    _primaryColor = color;
    _themeData = _isDarkMode ? darkTheme : lightTheme;
    await _settingsService.setThemeColor(_primaryColor);
    notifyListeners();
  }
}
