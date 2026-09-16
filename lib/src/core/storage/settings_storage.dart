import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences (theme mode, view settings) in
/// [SharedPreferences].
class SettingsStorage {
  const SettingsStorage(this._prefs);

  static const String _themeKey = 'glam.theme_mode';
  static const String _codeWrapKey = 'glam.code_wrap';

  final SharedPreferences _prefs;

  ThemeMode get themeMode => switch (_prefs.getString(_themeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);

  bool get codeWrap => _prefs.getBool(_codeWrapKey) ?? false;

  Future<void> setCodeWrap(bool value) => _prefs.setBool(_codeWrapKey, value);
}
