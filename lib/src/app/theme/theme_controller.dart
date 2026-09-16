import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

/// Light/dark/system preference, persisted via [SettingsStorage].
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsStorageProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsStorageProvider).setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
