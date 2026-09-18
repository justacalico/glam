import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/models/deploy_token.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Fields collected by the create dialog.
typedef DeployTokenDraft = ({
  String name,
  String? username,
  List<String> scopes,
  DateTime? expiresAt,
});

/// Deploy tokens with create / revoke, shared between project settings
/// and group detail. The secret is shown once after creation and never
/// returned again. Callers own persistence.
class DeployTokensSection extends StatelessWidget {
  const DeployTokensSection({
    required this.tokens,
    required this.onCreate,
    required this.onRevoke,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<DeployToken>> tokens;
  final Future<DeployToken> Function(DeployTokenDraft draft) onCreate;
  final Future<void> Function(DeployToken token) onRevoke;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.tokensDeployTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.actionAdd),
              onPressed: () => _create(context),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: AsyncValueWidget(
            value: tokens,
            onRetry: onRetry,
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.key_outlined,
                      title: context.l10n.tokensDeployEmpty,
                    ),
                  )
                : Column(
                    children: [
                      for (final t in list)
                        _DeployTokenTile(
                          token: t,
                          onRevoke: () => _revoke(context, t),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = TextEditingController();
    final username = TextEditingController();
    final days = TextEditingController();
    final scopes = {
      'read_repository': true,
      'read_registry': false,
      'write_registry': false,
      'read_package_registry': false,
      'write_package_registry': false,
    };
    var nameError = false;
    var scopeError = false;
    var daysError = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.tokenDeployCreate),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldName,
                    errorText: nameError ? context.l10n.errorRequired : null,
                  ),
                  onChanged: (_) {
                    if (nameError) {
                      setState(() => nameError = false);
                    }
                  },
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: username,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldUsernameOptional,
                  ),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldExpiresDays,
                    errorText: daysError
                        ? context.l10n.errorPositiveNumber
                        : null,
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
                      context.l10n.tokenScopeRequired,
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
              child: Text(context.l10n.actionCancel),
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
              child: Text(context.l10n.actionCreate),
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
      username: username.text.trim(),
      scopes: picked,
      expiresAt: expiryDays == null || expiryDays == 0
          ? null
          : DateTime.now().add(Duration(days: expiryDays)),
    );
    name.dispose();
    username.dispose();
    days.dispose();
    if (ok != true || draft.name.isEmpty || draft.scopes.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      final token = await (onCreate)((
        name: draft.name,
        scopes: draft.scopes,
        username: draft.username.isEmpty ? null : draft.username,
        expiresAt: draft.expiresAt,
      ));
      if (context.mounted && token.token != null) {
        unawaited(_showSecret(context, token));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// One-time display of the token secret. Not copyable from anywhere
  /// else once this dialog closes.
  Future<void> _showSecret(BuildContext context, DeployToken token) {
    // GitLab's default username is gitlab+deploy-token-{id}.
    final pair =
        '${token.username ?? 'gitlab+deploy-token-${token.id}'}'
        ':${token.token}';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tokenValueTitle(token.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.tokenCopyNow),
            const SizedBox(height: Insets.sm),
            SelectableText(
              pair,
              style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: Text(context.l10n.actionCopy),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: pair)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.actionCopied)),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionDone),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context, DeployToken t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tokenDeployRevokeConfirm),
        content: Text(context.l10n.p0StopsWorkingImmediately(t.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionRevoke),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await (onRevoke)(t);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _DeployTokenTile extends StatelessWidget {
  const _DeployTokenTile({required this.token, required this.onRevoke});

  final DeployToken token;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final t = token;
    final colors = context.colors;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.key_outlined,
        size: 18,
        color: t.revoked || t.expired ? colors.inkFaint : null,
      ),
      title: Text(t.name),
      subtitle: Text(
        [
          if (t.username != null) t.username!,
          t.scopes.join(', '),
          if (t.revoked)
            'revoked'
          else if (t.expired)
            'expired'
          else if (t.expiresAt != null)
            'expires ${Format.date(t.expiresAt!)}',
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        tooltip: context.l10n.actionRevoke,
        onPressed: onRevoke,
      ),
    );
  }
}
