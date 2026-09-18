import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

/// App locale override; null means follow the system locale.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => switch (ref.read(settingsStorageProvider).localeName) {
    'en' => const Locale('en'),
    'zh' => const Locale('zh'),
    _ => null,
  };

  /// Pass 'system', 'en', or 'zh'.
  Future<void> set(String name) async {
    state = switch (name) {
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      _ => null,
    };
    await ref.read(settingsStorageProvider).setLocaleName(name);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
