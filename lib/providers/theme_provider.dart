// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/local/local_storage_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = LocalStorageService.getThemeMode();
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    LocalStorageService.saveThemeMode(isDark ? 'dark' : 'light');
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    LocalStorageService.saveThemeMode('system');
    notifyListeners();
  }
}