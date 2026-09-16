import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/domain/account_models.dart';

/// SSH keys with add / delete.
class SshKeysSection extends ConsumerWidget {
  const SshKeysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(sshKeysProvider);

    return _Section(
      label: 'SSH keys',
      trailing: TextButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        onPressed: () => _addKey(context, ref),
      ),
      children: [
        keys.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _ErrorTile(error: e),
          data: (list) => list.isEmpty
              ? const ListTile(dense: true, title: Text('No SSH keys'))
              : Column(
                  children: [
                    for (final k in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.key_outlined, size: 18),
                        title: Text(k.title),
                        subtitle: Text(
                          [
                            k.fingerprint,
                            if (k.expiresAt != null)
                              'expires ${Format.date(k.expiresAt!)}',
                            if (k.lastUsedAt != null)
                              'used ${Format.date(k.lastUsedAt!)}',
                          ].join(' · '),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _deleteKey(context, ref, k),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _addKey(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final key = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add SSH key'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: key,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Public key',
                  hintText: 'ssh-ed25519 AAAA…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty || key.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final t = title.text.trim();
    final k = key.text.trim();
    title.dispose();
    key.dispose();
    if (ok != true || t.isEmpty || k.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).addSshKey(title: t, key: k);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  Future<void> _deleteKey(BuildContext context, WidgetRef ref, SshKey k) async {
    final ok = await _confirm(context, title: 'Remove SSH key?', body: k.title);
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).deleteSshKey(k.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}

/// Personal access tokens (list + revoke — tokens are created on
/// the GitLab site, the API only exposes list/revoke).
class TokensSection extends ConsumerWidget {
  const TokensSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(personalAccessTokensProvider);

    return _Section(
      label: 'Access tokens',
      children: [
        tokens.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _ErrorTile(error: e),
          data: (list) => list.isEmpty
              ? const ListTile(dense: true, title: Text('No active tokens'))
              : Column(
                  children: [
                    for (final t in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.badge_outlined, size: 18),
                        title: Text(t.name),
                        subtitle: Text(
                          [
                            t.scopes.join(', '),
                            if (t.expiresAt != null)
                              t.expired
                                  ? 'expired ${Format.date(t.expiresAt!)}'
                                  : 'expires ${Format.date(t.expiresAt!)}',
                            if (t.lastUsedAt != null)
                              'used ${Format.date(t.lastUsedAt!)}',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.block, size: 18),
                          tooltip: 'Revoke',
                          onPressed: () => _revoke(context, ref, t),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    PersonalAccessToken t,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Revoke token?',
      body: '"${t.name}" stops working immediately.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).revokeToken(t.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}

/// Global notification level + custom event toggles.
class NotificationSection extends ConsumerWidget {
  const NotificationSection({super.key});

  static const _eventLabels = {
    'new_note': 'New comments',
    'new_issue': 'New issues',
    'reopen_issue': 'Reopened issues',
    'close_issue': 'Closed issues',
    'reassign_issue': 'Reassigned issues',
    'issue_due': 'Issue due dates',
    'new_merge_request': 'New merge requests',
    'push_to_merge_request': 'Pushes to merge requests',
    'reopen_merge_request': 'Reopened merge requests',
    'close_merge_request': 'Closed merge requests',
    'reassign_merge_request': 'Reassigned merge requests',
    'merge_merge_request': 'Merged merge requests',
    'failed_pipeline': 'Failed pipelines',
    'fixed_pipeline': 'Fixed pipelines',
    'success_pipeline': 'Successful pipelines',
    'moved_project': 'Moved projects',
    'new_epic': 'New epics',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return _Section(
      label: 'Notifications',
      children: [
        settings.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _ErrorTile(error: e),
          data: (s) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: Row(
                  children: [
                    const Expanded(child: Text('Level')),
                    DropdownButton<String>(
                      value:
                          NotificationSettings.levelLabels.containsKey(s.level)
                          ? s.level
                          : 'global',
                      items: [
                        for (final e
                            in NotificationSettings.levelLabels.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          unawaited(_setLevel(context, ref, v));
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (s.level == 'custom')
                for (final e in _eventLabels.entries)
                  SwitchListTile(
                    dense: true,
                    title: Text(e.value),
                    value: s.events[e.key] ?? false,
                    onChanged: (v) =>
                        unawaited(_toggleEvent(context, ref, e.key, v)),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setLevel(
    BuildContext context,
    WidgetRef ref,
    String level,
  ) async {
    try {
      await ref.read(accountActionsProvider).setNotificationLevel(level);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  Future<void> _toggleEvent(
    BuildContext context,
    WidgetRef ref,
    String event,
    bool on,
  ) async {
    try {
      await ref.read(accountActionsProvider).toggleNotificationEvent(event, on);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children, this.trailing});

  final String label;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.lg,
            Insets.lg,
            Insets.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: colors.inkMuted,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, title: Text('$error'));
  }
}

void _error(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}
