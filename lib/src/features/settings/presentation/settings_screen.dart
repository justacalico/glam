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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        children: [
          _Section(
            label: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.sm,
                ),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
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
            label: 'Session',
            children: [
              if (session != null)
                ListTile(
                  leading: Icon(Icons.dns_outlined, color: colors.inkMuted),
                  title: Text(session.baseUrl),
                  subtitle: Text('Signed in as @${session.user.username}'),
                ),
              ListTile(
                leading: Icon(Icons.logout, color: colors.danger),
                title: Text('Sign out', style: TextStyle(color: colors.danger)),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
          _Section(
            label: 'About',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Glam'),
                subtitle: Text('A GitLab client for desktop and mobile'),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('GitLab instance'),
                subtitle: ref
                    .watch(instanceVersionProvider)
                    .when(
                      data: (v) => Text(
                        v.revision.isEmpty
                            ? 'Version ${v.version}'
                            : 'Version ${v.version} (${v.revision})',
                      ),
                      loading: () => const Text('Checking version...'),
                      error: (_, _) => const Text('Version unavailable'),
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
        title: const Text('Sign out?'),
        content: const Text('Your token is removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
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
