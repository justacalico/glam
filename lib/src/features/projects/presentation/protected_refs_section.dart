import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/protected_tag.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Protected branch rules with protect / unprotect.
class ProtectedBranchesSection extends ConsumerWidget {
  const ProtectedBranchesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final branches = ref.watch(projectProtectedBranchesProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Protected branches')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Protect'),
              onPressed: () => _protect(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: branches.when(
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
                      icon: Icons.shield_outlined,
                      title: 'No protected branches',
                    ),
                  )
                : Column(
                    children: [
                      for (final b in list)
                        _ProtectedBranchTile(
                          branch: b,
                          onDelete: () => _unprotect(context, ref, b),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _protect(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    var pushLevel = 40;
    var mergeLevel = 40;
    var forcePush = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Protect branch'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Branch or wildcard',
                    hintText: 'main or release-*',
                  ),
                ),
                const SizedBox(height: Insets.md),
                _LevelPicker(
                  label: 'Allowed to push',
                  value: pushLevel,
                  onChanged: (v) => setState(() => pushLevel = v),
                ),
                _LevelPicker(
                  label: 'Allowed to merge',
                  value: mergeLevel,
                  onChanged: (v) => setState(() => mergeLevel = v),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Allow force push'),
                  value: forcePush,
                  onChanged: (v) => setState(() => forcePush = v ?? false),
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
                if (name.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Protect'),
            ),
          ],
        ),
      ),
    );
    final branch = name.text.trim();
    name.dispose();
    if (ok != true || branch.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .protectBranch(
            project.id,
            name: branch,
            pushLevel: pushLevel,
            mergeLevel: mergeLevel,
            allowForcePush: forcePush,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _unprotect(
    BuildContext context,
    WidgetRef ref,
    ProtectedBranch b,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Unprotect branch?',
      body: '"${b.name}" will accept pushes again.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .unprotectBranch(project.id, b.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _ProtectedBranchTile extends StatelessWidget {
  const _ProtectedBranchTile({required this.branch, required this.onDelete});

  final ProtectedBranch branch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final push = branch.pushLevels.map(ProtectedBranch.levelLabel).join(', ');
    final merge = branch.mergeLevels.map(ProtectedBranch.levelLabel).join(', ');
    return ListTile(
      dense: true,
      leading: Icon(
        branch.isWildcard ? Icons.star_outline : Icons.shield_outlined,
        size: 18,
      ),
      title: Text(
        branch.name,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5),
      ),
      subtitle: Text(
        [
          'push: $push',
          'merge: $merge',
          if (branch.allowForcePush) 'force push allowed',
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
          items: const [
            DropdownMenuItem(value: 0, child: Text('No one')),
            DropdownMenuItem(
              value: 30,
              child: Text('Developers + maintainers'),
            ),
            DropdownMenuItem(value: 40, child: Text('Maintainers')),
            DropdownMenuItem(value: 60, child: Text('Admins')),
          ],
        ),
      ],
    );
  }
}

/// Protected tag rules with protect / unprotect.
class ProtectedTagsSection extends ConsumerWidget {
  const ProtectedTagsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tags = ref.watch(projectProtectedTagsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Protected tags')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Protect'),
              onPressed: () => _protect(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: tags.when(
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
                      icon: Icons.sell_outlined,
                      title: 'No protected tags',
                    ),
                  )
                : Column(
                    children: [
                      for (final t in list)
                        _ProtectedTagTile(
                          tag: t,
                          onDelete: () => _unprotect(context, ref, t),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _protect(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    var createLevel = 40;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Protect tag'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tag or wildcard',
                    hintText: 'v1.0.0 or v*',
                  ),
                ),
                const SizedBox(height: Insets.md),
                _LevelPicker(
                  label: 'Allowed to create',
                  value: createLevel,
                  onChanged: (v) => setState(() => createLevel = v),
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
                if (name.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Protect'),
            ),
          ],
        ),
      ),
    );
    final tag = name.text.trim();
    name.dispose();
    if (ok != true || tag.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .protectTag(project.id, name: tag, createLevel: createLevel);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _unprotect(
    BuildContext context,
    WidgetRef ref,
    ProtectedTag tag,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Unprotect tag?',
      body: '"${tag.name}" can be created by anyone with push access.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .unprotectTag(project.id, tag.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _ProtectedTagTile extends StatelessWidget {
  const _ProtectedTagTile({required this.tag, required this.onDelete});

  final ProtectedTag tag;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final create = tag.createLabels.isEmpty ? '—' : tag.createLabels.join(', ');
    return ListTile(
      dense: true,
      leading: Icon(
        tag.isWildcard ? Icons.star_outline : Icons.sell_outlined,
        size: 18,
      ),
      title: Text(
        tag.name,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5),
      ),
      subtitle: Text('create: $create'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}
