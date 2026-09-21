import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات عامة على مستوى التطبيق: الثيم واللغة.
/// محفوظة محليا وتتطبق فوريا على كل الشاشات.
class AppSettings extends ChangeNotifier {
  static const _themeKey = 'ast_theme_mode';
  static const _localeKey = 'ast_locale';

  ThemeMode themeMode = ThemeMode.light;
  Locale locale = const Locale('en');

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isArabic => locale.languageCode == 'ar';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode =
        (p.getString(_themeKey) ?? 'light') == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
    locale = Locale(p.getString(_localeKey) ?? 'en');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeKey, isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    locale = isArabic ? const Locale('en') : const Locale('ar');
    final p = await SharedPreferences.getInstance();
    await p.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}

/// نسخة واحدة عامة يستمع لها MaterialApp وكل الشاشات.
final appSettings = AppSettings();
