import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/features/account/application/account_providers.dart';
import 'package:glam/src/features/account/domain/account_models.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

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

/// GPG keys used for commit signing, with add / delete.
class GpgKeysSection extends ConsumerWidget {
  const GpgKeysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(gpgKeysProvider);

    return _Section(
      label: 'GPG keys',
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
              ? const ListTile(dense: true, title: Text('No GPG keys'))
              : Column(
                  children: [
                    for (final k in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                        ),
                        title: Text(
                          k.emails.isEmpty
                              ? 'GPG key #${k.id}'
                              : k.emails.first,
                        ),
                        subtitle: Text(
                          [
                            if (k.subkeyIds.isNotEmpty) k.subkeyIds.first,
                            if (k.createdAt != null)
                              'added ${Format.date(k.createdAt!)}',
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
    final key = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add GPG key'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: key,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Public key',
              hintText: '-----BEGIN PGP PUBLIC KEY BLOCK-----',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final k = key.text.trim();
    key.dispose();
    if (ok != true || k.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).addGpgKey(k);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  Future<void> _deleteKey(BuildContext context, WidgetRef ref, GpgKey k) async {
    final label = k.emails.isEmpty ? 'key #${k.id}' : k.emails.first;
    final ok = await _confirm(context, title: 'Remove GPG key?', body: label);
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).deleteGpgKey(k.id);
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
    final currentId = ref.watch(currentTokenProvider).value;

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
                            if (t.id == currentId) 'this session',
                            if (t.expiresAt != null)
                              t.expired
                                  ? 'expired ${Format.date(t.expiresAt!)}'
                                  : 'expires ${Format.date(t.expiresAt!)}',
                            if (t.lastUsedAt != null)
                              'used ${Format.date(t.lastUsedAt!)}',
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (t.id == currentId)
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                tooltip: 'Rotate',
                                onPressed: () => _rotate(context, ref, t),
                              ),
                            IconButton(
                              icon: const Icon(Icons.block, size: 18),
                              tooltip: 'Revoke',
                              onPressed: () =>
                                  _revoke(context, ref, t, t.id == currentId),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Rotates the session token, persists the replacement, and shows
  /// the new cleartext once.
  Future<void> _rotate(
    BuildContext context,
    WidgetRef ref,
    PersonalAccessToken t,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Rotate token?',
      body:
          '"${t.name}" stops working immediately. A replacement is '
          'created and stored.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      final rotated = await ref
          .read(accountActionsProvider)
          .rotateCurrentToken();
      final cleartext = rotated.token;
      if (cleartext == null) {
        throw const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'GitLab did not return a token',
        );
      }
      await ref.read(sessionProvider.notifier).replaceToken(cleartext);
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Token rotated'),
            content: SelectableText('New token (shown once):\n\n$cleartext'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    PersonalAccessToken t,
    bool isCurrent,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Revoke token?',
      body: isCurrent
          ? '"${t.name}" is this session\'s token — revoking signs you out.'
          : '"${t.name}" stops working immediately.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).revokeToken(t.id);
      if (isCurrent) {
        await ref.read(sessionProvider.notifier).signOut();
      }
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

/// Email addresses on the account, with add / remove.
class EmailsSection extends ConsumerWidget {
  const EmailsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emails = ref.watch(emailsProvider);
    final colors = context.colors;

    return _Section(
      label: 'Emails',
      trailing: TextButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        onPressed: () => _addEmail(context, ref),
      ),
      children: [
        emails.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _ErrorTile(error: e),
          data: (list) => list.isEmpty
              ? const ListTile(dense: true, title: Text('No emails'))
              : Column(
                  children: [
                    for (final m in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.mail_outline, size: 18),
                        title: Text(m.email),
                        subtitle: Text(
                          [
                            if (m.primary) 'primary',
                            m.confirmed ? 'confirmed' : 'unconfirmed',
                          ].join(' · '),
                        ),
                        trailing: m.primary
                            ? null
                            : IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: colors.danger,
                                ),
                                onPressed: () => _deleteEmail(context, ref, m),
                              ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _addEmail(BuildContext context, WidgetRef ref) async {
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add email'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (email.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final e = email.text.trim();
    email.dispose();
    if (ok != true || e.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).addEmail(e);
    } on ApiException catch (err) {
      if (context.mounted) {
        _error(context, err.message);
      }
    }
  }

  Future<void> _deleteEmail(
    BuildContext context,
    WidgetRef ref,
    UserEmail m,
  ) async {
    final ok = await _confirm(context, title: 'Remove email?', body: m.email);
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(accountActionsProvider).deleteEmail(m.id);
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

/// GitLab-side account preferences (`/user/preferences`) — the ones the
/// app doesn't manage locally.
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);

    return _Section(
      label: 'GitLab preferences',
      children: [
        prefs.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _ErrorTile(error: e),
          data: (p) => Column(
            children: [
              _toggle(
                context,
                ref,
                'Show whitespace changes in diffs',
                p.showWhitespaceInDiffs,
                'show_whitespace_in_diffs',
              ),
              _toggle(
                context,
                ref,
                'Show one file at a time in diffs',
                p.viewDiffsFileByFile,
                'view_diffs_file_by_file',
              ),
              _toggle(
                context,
                ref,
                'Include unstaged changes in diffs',
                p.passUnstagedChangesInDiff,
                'pass_unstaged_changes_in_diff',
              ),
              _toggle(
                context,
                ref,
                'Markdown surrounds selection',
                p.markdownSurroundSelection,
                'markdown_surround_selection',
              ),
              _toggle(
                context,
                ref,
                'Automatic markdown lists',
                p.markdownAutomaticLists,
                'markdown_automatic_lists',
              ),
              _choice(context, ref, 'Layout width', p.layoutWidth, const {
                'fixed': 'Fixed',
                'fluid': 'Fluid',
              }, 'layout_width'),
              _choice(
                context,
                ref,
                'Default projects view',
                p.projectsView,
                const {
                  'activity': 'Activity',
                  'starred': 'Starred',
                  'trending': 'Trending',
                },
                'projects_view',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggle(
    BuildContext context,
    WidgetRef ref,
    String title,
    bool value,
    String field,
  ) {
    return SwitchListTile(
      dense: true,
      title: Text(title),
      value: value,
      onChanged: (v) => unawaited(_set(context, ref, {field: v})),
    );
  }

  Widget _choice(
    BuildContext context,
    WidgetRef ref,
    String title,
    String? current,
    Map<String, String> options,
    String field,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          DropdownButton<String>(
            value: options.containsKey(current) ? current : null,
            hint: const Text('Default'),
            items: [
              for (final e in options.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) {
              if (v != null) {
                unawaited(_set(context, ref, {field: v}));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fields,
  ) async {
    try {
      await ref.read(accountActionsProvider).updateUserPreference(fields);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}
