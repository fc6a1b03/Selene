import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2c3e50),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFf8f9fa),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFffffff),
      foregroundColor: Color(0xFF2c3e50),
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFffffff),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2c3e50)),
      bodyMedium: TextStyle(color: Color(0xFF2c3e50)),
      bodySmall: TextStyle(color: Color(0xFF7f8c8d)),
      titleLarge: TextStyle(color: Color(0xFF2c3e50)),
      titleMedium: TextStyle(color: Color(0xFF2c3e50)),
      titleSmall: TextStyle(color: Color(0xFF2c3e50)),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2c3e50),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1e1e1e),
      foregroundColor: Color(0xFFffffff),
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1e1e1e),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFffffff)),
      bodyMedium: TextStyle(color: Color(0xFFffffff)),
      bodySmall: TextStyle(color: Color(0xFFb0b0b0)),
      titleLarge: TextStyle(color: Color(0xFFffffff)),
      titleMedium: TextStyle(color: Color(0xFFffffff)),
      titleSmall: TextStyle(color: Color(0xFFffffff)),
    ),
  );
}
