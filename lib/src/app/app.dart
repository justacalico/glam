import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/l10n/app_localizations.dart';
import 'package:glam/src/app/app_router.dart';
import 'package:glam/src/app/locale_controller.dart';
import 'package:glam/src/app/theme/app_theme.dart';
import 'package:glam/src/app/theme/theme_controller.dart';

/// Root widget: wires the router, themes, and global providers.
class GlamApp extends ConsumerWidget {
  const GlamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Glam',
      debugShowCheckedModeBanner: false,
      theme: GlamTheme.light(),
      darkTheme: GlamTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
