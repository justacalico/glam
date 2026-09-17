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
            const Expanded(child: SectionLabel('Shared groups')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Share'),
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
              ? const Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: EmptyState(
                    icon: Icons.group_outlined,
                    title: 'Not shared with any group',
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
        const SnackBar(content: Text('No groups left to share with')),
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
          title: const Text('Share with group'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: groupId,
                  decoration: const InputDecoration(labelText: 'Group'),
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
                const SizedBox(height: Insets.sm),
                DropdownButtonFormField<int>(
                  initialValue: accessLevel,
                  decoration: const InputDecoration(
                    labelText: 'Max access level',
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Expires in days (optional)',
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Share'),
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
      title: 'Remove group share?',
      body: '"${group.displayName}" loses access to this project.',
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
      title: Text(group.displayName),
      subtitle: Text(
        [
          group.roleLabel,
          if (group.expiresAt != null)
            'expires ${Format.date(group.expiresAt!)}',
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, size: 18),
        tooltip: 'Unshare',
        onPressed: onRemove,
      ),
    );
  }
}
