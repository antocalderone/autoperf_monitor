// lib/theme/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:cartrackerevo/services/settings_service.dart';

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

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[200],
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      useMaterial3: true,
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: colorScheme.onSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[400],
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      useMaterial3: true,
    );
  }

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
