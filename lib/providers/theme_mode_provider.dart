import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Houdt de gekozen weergave-modus (licht / donker / systeem) bij en
/// persisted deze lokaal zodat de keuze tussen sessies bewaard blijft.
class ThemeModeProvider extends ChangeNotifier {
  static const String _prefKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    ThemeMode mode = ThemeMode.system;
    if (value == 'light') {
      mode = ThemeMode.light;
    } else if (value == 'dark') {
      mode = ThemeMode.dark;
    }
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_prefKey, value);
  }

  /// Doorloop Systeem -> Licht -> Donker -> Systeem met één knop.
  void cycle() {
    final next = _themeMode == ThemeMode.system
        ? ThemeMode.light
        : _themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.system;
    setThemeMode(next);
  }
}
