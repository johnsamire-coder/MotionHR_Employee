import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _keyTheme = 'app_theme';
  static const String defaultTheme = 'light';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  static final ValueNotifier<String> currentThemeNotifier =
      ValueNotifier<String>(defaultTheme);

  /// Load theme from SharedPreferences on app startup
  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_keyTheme) ?? defaultTheme;
    currentThemeNotifier.value = savedTheme;
    themeModeNotifier.value = _toThemeMode(savedTheme);
  }

  /// Save and apply a new theme
  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
    currentThemeNotifier.value = theme;
    themeModeNotifier.value = _toThemeMode(theme);
  }

  static ThemeMode _toThemeMode(String theme) {
    switch (theme) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
