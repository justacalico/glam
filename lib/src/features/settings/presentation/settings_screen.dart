import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/app/locale_controller.dart';
import 'package:glam/src/app/theme/theme_controller.dart';
import 'package:glam/src/core/utils/l10n.dart';
import 'package:glam/src/core/widgets/section_header.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/presentation/account_sections.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

/// App settings: theme, code viewing, instance info, sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final session = ref.watch(sessionProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        children: [
          _Section(
            label: context.l10n.settingsAppearance,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.sm,
                ),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(context.l10n.languageSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(context.l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(context.l10n.themeDark),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (modes) =>
                      ref.read(themeModeProvider.notifier).set(modes.first),
                ),
              ),
            ],
          ),
          _Section(
            label: context.l10n.settingsLanguage,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.sm,
                ),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'system',
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(context.l10n.languageSystem),
                    ),
                    const ButtonSegment(value: 'en', label: Text('English')),
                    const ButtonSegment(value: 'zh', label: Text('简体中文')),
                  ],
                  selected: {_localeName(ref.watch(localeProvider))},
                  onSelectionChanged: (names) =>
                      ref.read(localeProvider.notifier).set(names.first),
                ),
              ),
            ],
          ),
          const SshKeysSection(),
          const GpgKeysSection(),
          const EmailsSection(),
          const TokensSection(),
          const NotificationSection(),
          const PreferencesSection(),
          _Section(
            label: context.l10n.settingsSession,
            children: [
              if (session != null)
                ListTile(
                  leading: Icon(Icons.dns_outlined, color: colors.inkMuted),
                  title: Text(session.baseUrl),
                  subtitle: Text(
                    context.l10n.signedInAs(session.user.username),
                  ),
                ),
              ListTile(
                leading: Icon(Icons.logout, color: colors.danger),
                title: Text(
                  context.l10n.actionSignOut,
                  style: TextStyle(color: colors.danger),
                ),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
          _Section(
            label: context.l10n.settingsAbout,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Glam'),
                subtitle: Text(context.l10n.aboutTagline),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(context.l10n.aboutInstance),
                subtitle: ref
                    .watch(instanceVersionProvider)
                    .when(
                      data: (v) => Text(
                        v.revision.isEmpty
                            ? context.l10n.aboutVersion(v.version)
                            : context.l10n.aboutVersionRev(
                                v.version,
                                v.revision,
                              ),
                      ),
                      loading: () => Text(context.l10n.aboutVersionChecking),
                      error: (_, _) =>
                          Text(context.l10n.aboutVersionUnavailable),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.signOutConfirmTitle),
        content: Text(context.l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionSignOut),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await ref.read(sessionProvider.notifier).signOut();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: label),
        ...children,
      ],
    );
  }
}

String _localeName(Locale? locale) => switch (locale?.languageCode) {
  'en' => 'en',
  'zh' => 'zh',
  _ => 'system',
};
