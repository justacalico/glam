import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/shared_group.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Groups this project is shared with, plus share / unshare actions.
class SharingSection extends ConsumerWidget {
  const SharingSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final shared = project.sharedWithGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(context.l10n.sharedGroups)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.share),
              onPressed: () => _share(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: shared.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: EmptyState(
                    icon: Icons.group_outlined,
                    title: context.l10n.notSharedWithAnyGroup,
                  ),
                )
              : Column(
                  children: [
                    for (final g in shared)
                      _SharedGroupTile(
                        group: g,
                        onRemove: () => _unshare(context, ref, g),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(groupsProvider(null).future);
    final sharedIds = project.sharedWithGroups.map((g) => g.groupId).toSet();
    final candidates = groups.items
        .where((g) => !sharedIds.contains(g.id))
        .toList();
    if (!context.mounted) {
      return;
    }
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noGroupsLeftToShareWith)),
      );
      return;
    }
    var groupId = candidates.first.id;
    var accessLevel = 30;
    final days = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.shareWithGroup),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: groupId,
                  decoration: InputDecoration(labelText: context.l10n.group),
                  items: [
                    for (final g in candidates)
                      DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          g.fullPath.isEmpty ? g.name : g.fullPath,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => groupId = v ?? groupId),
                ),
                SizedBox(height: Insets.sm),
                DropdownButtonFormField<int>(
                  initialValue: accessLevel,
                  decoration: InputDecoration(
                    labelText: context.l10n.maxAccessLevel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 10,
                      child: Text(context.l10n.roleGuest),
                    ),
                    DropdownMenuItem(
                      value: 20,
                      child: Text(context.l10n.roleReporter),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(context.l10n.roleDeveloper),
                    ),
                    DropdownMenuItem(
                      value: 40,
                      child: Text(context.l10n.roleMaintainer),
                    ),
                  ],
                  onChanged: (v) => setState(() => accessLevel = v ?? 30),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldExpiresDays,
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
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.share),
            ),
          ],
        ),
      ),
    );
    final expiryDays = int.tryParse(days.text.trim());
    days.dispose();
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .shareProject(
            project,
            groupId: groupId,
            accessLevel: accessLevel,
            expiresAt: expiryDays == null
                ? null
                : DateTime.now().add(Duration(days: expiryDays)),
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _unshare(
    BuildContext context,
    WidgetRef ref,
    SharedGroup group,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: context.l10n.removeGroupShare,
      body: context.l10n.shareRemoveBody(group.displayName),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .unshareProject(project, group.groupId);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _SharedGroupTile extends StatelessWidget {
  const _SharedGroupTile({required this.group, required this.onRemove});

  final SharedGroup group;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      leading: Icon(Icons.group_outlined, size: 18, color: colors.inkMuted),
      title: Text(group.localizedName(context.l10n)),
      subtitle: Text(
        [
          group.roleLabel,
          if (group.expiresAt != null)
            'expires ${Format.date(group.expiresAt!)}',
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline, size: 18),
        tooltip: context.l10n.unshare,
        onPressed: onRemove,
      ),
    );
  }
}
