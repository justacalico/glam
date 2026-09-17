import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_access_token.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Project access tokens with create / revoke. The secret is shown
/// once after creation and never returned again.
class AccessTokensSection extends ConsumerWidget {
  const AccessTokensSection({required this.project, super.key});

  final Project project;

  static const _scopes = {
    'api': true,
    'read_api': false,
    'read_repository': false,
    'write_repository': false,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tokens = ref.watch(projectAccessTokensProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Project access tokens')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _create(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: tokens.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text('$e'),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.token_outlined,
                      title: 'No project access tokens',
                    ),
                  )
                : Column(
                    children: [
                      for (final t in list)
                        _AccessTokenTile(
                          token: t,
                          onRevoke: () => _revoke(context, ref, t),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final days = TextEditingController();
    final scopes = Map.of(_scopes);
    var accessLevel = 30;
    var nameError = false;
    var scopeError = false;
    var daysError = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create project access token'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: nameError ? 'Required' : null,
                  ),
                  onChanged: (_) {
                    if (nameError) {
                      setState(() => nameError = false);
                    }
                  },
                ),
                const SizedBox(height: Insets.sm),
                DropdownButtonFormField<int>(
                  initialValue: accessLevel,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('Guest')),
                    DropdownMenuItem(value: 20, child: Text('Reporter')),
                    DropdownMenuItem(value: 30, child: Text('Developer')),
                    DropdownMenuItem(value: 40, child: Text('Maintainer')),
                  ],
                  onChanged: (v) => setState(() => accessLevel = v ?? 30),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Expires in days (optional)',
                    errorText: daysError ? 'Must be a positive number' : null,
                  ),
                  onChanged: (_) {
                    if (daysError) {
                      setState(() => daysError = false);
                    }
                  },
                ),
                const SizedBox(height: Insets.sm),
                for (final e in scopes.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(e.key),
                    value: e.value,
                    onChanged: (v) =>
                        setState(() => scopes[e.key] = v ?? false),
                  ),
                if (scopeError)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xs),
                    child: Text(
                      'Pick at least one scope',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
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
                final daysText = days.text.trim();
                final parsedDays = daysText.isEmpty
                    ? 0
                    : int.tryParse(daysText);
                final badName = name.text.trim().isEmpty;
                final badScopes = !scopes.values.any((v) => v);
                final badDays = daysText.isNotEmpty && (parsedDays ?? 0) <= 0;
                if (badName || badScopes || badDays) {
                  setState(() {
                    nameError = badName;
                    scopeError = badScopes;
                    daysError = badDays;
                  });
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    final picked = scopes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final expiryDays = int.tryParse(days.text.trim());
    final draft = (
      name: name.text.trim(),
      accessLevel: accessLevel,
      scopes: picked,
      expiresAt: expiryDays == null
          ? null
          : DateTime.now().add(Duration(days: expiryDays)),
    );
    name.dispose();
    days.dispose();
    if (ok != true || draft.name.isEmpty || draft.scopes.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      final token = await ref
          .read(projectAdminActionsProvider)
          .addAccessToken(
            project.id,
            name: draft.name,
            scopes: draft.scopes,
            accessLevel: draft.accessLevel,
            expiresAt: draft.expiresAt,
          );
      if (context.mounted && token.token != null) {
        unawaited(_showSecret(context, token));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _showSecret(BuildContext context, ProjectAccessToken token) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Token "${token.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this now — it will not be shown again.'),
            const SizedBox(height: Insets.sm),
            SelectableText(
              token.token ?? '',
              style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('Copy'),
            onPressed: () {
              unawaited(
                Clipboard.setData(ClipboardData(text: token.token ?? '')),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    ProjectAccessToken t,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Revoke access token?',
      body: '"${t.name}" stops working immediately.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .revokeAccessToken(project.id, t.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _AccessTokenTile extends StatelessWidget {
  const _AccessTokenTile({required this.token, required this.onRevoke});

  final ProjectAccessToken token;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final t = token;
    final colors = context.colors;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.token_outlined,
        size: 18,
        color: t.revoked || t.expired ? colors.inkFaint : null,
      ),
      title: Text(t.name),
      subtitle: Text(
        [
          t.roleLabel,
          t.scopes.join(', '),
          if (t.revoked)
            'revoked'
          else if (t.expired)
            'expired'
          else if (t.expiresAt != null)
            'expires ${Format.date(t.expiresAt!)}',
        ].join(' · '),
      ),
      trailing: t.revoked
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Revoke',
              onPressed: onRevoke,
            ),
    );
  }
}
