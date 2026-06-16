import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = HiveStorage.getSetting('dark_mode', defaultValue: false);
    _themeMode = isDark == true ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    HiveStorage.saveSetting('dark_mode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
