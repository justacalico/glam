import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Deploy keys with add / remove.
class DeployKeysSection extends ConsumerWidget {
  const DeployKeysSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final keys = ref.watch(projectDeployKeysProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Deploy keys')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.actionAdd),
              onPressed: () => _addKey(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: keys.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text('$e'),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.vpn_key_outlined,
                      title: context.l10n.noDeployKeys,
                    ),
                  )
                : Column(
                    children: [
                      for (final k in list)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.vpn_key_outlined, size: 18),
                          title: Text(k.title),
                          subtitle: Text(
                            [
                              k.fingerprint,
                              if (k.canPush) 'write access',
                              if (k.createdAt != null)
                                'added ${Format.date(k.createdAt!)}',
                            ].join(' · '),
                            style: const TextStyle(
                              fontFamily: GlamFonts.mono,
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
        ),
      ],
    );
  }

  Future<void> _addKey(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final key = TextEditingController();
    var canPush = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.addDeployKey),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldTitle,
                  ),
                ),
                SizedBox(height: Insets.sm),
                TextField(
                  controller: key,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: context.l10n.publicKey,
                    hintText: context.l10n.sshEd25519Aaaa,
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(context.l10n.grantWriteAccess),
                  value: canPush,
                  onChanged: (v) => setState(() => canPush = v ?? false),
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
                if (title.text.trim().isEmpty || key.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.l10n.actionAdd),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) {
      title.dispose();
      key.dispose();
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .addDeployKey(
            project.id,
            title: title.text.trim(),
            key: key.text.trim(),
            canPush: canPush,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    } finally {
      title.dispose();
      key.dispose();
    }
  }

  Future<void> _deleteKey(
    BuildContext context,
    WidgetRef ref,
    DeployKey k,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: context.l10n.removeDeployKey,
      body: k.title,
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteDeployKey(project.id, k.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}
