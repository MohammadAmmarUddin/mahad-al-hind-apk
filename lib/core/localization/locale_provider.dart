import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final saved = HiveStorage.getSetting('language', defaultValue: 'en');
    _locale = Locale(saved);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (!['en', 'bn'].contains(locale.languageCode)) return;
    _locale = locale;
    HiveStorage.saveSetting('language', locale.languageCode);
    notifyListeners();
  }
}
