import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePrefKey);

    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    // Notify listeners only after loading, if needed (usually handled by initial build)
    // notifyListeners(); // Might cause issues if called before initial build completes
  }

  // Set and save the theme preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // No change needed

    _themeMode = mode;
    notifyListeners(); // Notify listeners of the change

    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
    }
    await prefs.setString(_themePrefKey, themeString);
  }

  // Helper method to toggle between light and dark mode (can be expanded)
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
