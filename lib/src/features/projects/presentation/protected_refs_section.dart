import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/freeze_period.dart';
import 'package:glam/src/features/projects/domain/protected_environment.dart';
import 'package:glam/src/features/projects/domain/protected_tag.dart';
import 'package:glam/src/features/projects/domain/remote_mirror.dart';
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

/// Protected environment rules with protect / unprotect.
class ProtectedEnvironmentsSection extends ConsumerWidget {
  const ProtectedEnvironmentsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final envs = ref.watch(projectProtectedEnvironmentsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Protected environments')),
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
          child: envs.when(
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
                      icon: Icons.cloud_outlined,
                      title: 'No protected environments',
                    ),
                  )
                : Column(
                    children: [
                      for (final e in list)
                        _ProtectedEnvironmentTile(
                          env: e,
                          onDelete: () => _unprotect(context, ref, e),
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
    var deployLevel = 40;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Protect environment'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Environment or wildcard',
                    hintText: 'production or review/*',
                  ),
                ),
                const SizedBox(height: Insets.md),
                _LevelPicker(
                  label: 'Allowed to deploy',
                  value: deployLevel,
                  onChanged: (v) => setState(() => deployLevel = v),
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
    final env = name.text.trim();
    name.dispose();
    if (ok != true || env.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .protectEnvironment(project.id, name: env, deployLevel: deployLevel);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _unprotect(
    BuildContext context,
    WidgetRef ref,
    ProtectedEnvironment env,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Unprotect environment?',
      body: '"${env.name}" will accept deploys again.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .unprotectEnvironment(project.id, env.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _ProtectedEnvironmentTile extends StatelessWidget {
  const _ProtectedEnvironmentTile({required this.env, required this.onDelete});

  final ProtectedEnvironment env;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deploy = env.deployLevels.map(ProtectedBranch.levelLabel).join(', ');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.cloud_outlined, size: 18),
      title: Text(
        env.name,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5),
      ),
      subtitle: Text('deploy: ${deploy.isEmpty ? 'none' : deploy}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}

/// Deploy freeze windows with create / edit / delete.
class FreezePeriodsSection extends ConsumerWidget {
  const FreezePeriodsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final periods = ref.watch(projectFreezePeriodsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Deploy freezes')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add freeze'),
              onPressed: () => _edit(context, ref, null),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: periods.when(
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
                      icon: Icons.ac_unit_outlined,
                      title: 'No deploy freezes',
                    ),
                  )
                : Column(
                    children: [
                      for (final p in list)
                        _FreezePeriodTile(
                          period: p,
                          onEdit: () => _edit(context, ref, p),
                          onDelete: () => _delete(context, ref, p),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    FreezePeriod? existing,
  ) async {
    final start = TextEditingController(text: existing?.freezeStart ?? '');
    final end = TextEditingController(text: existing?.freezeEnd ?? '');
    final zone = TextEditingController(text: existing?.cronTimezone ?? 'UTC');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add deploy freeze' : 'Edit freeze'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: start,
                autofocus: existing == null,
                decoration: const InputDecoration(
                  labelText: 'Freeze start (cron)',
                  hintText: '0 23 * * 5',
                ),
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: end,
                decoration: const InputDecoration(
                  labelText: 'Freeze end (cron)',
                  hintText: '0 7 * * 1',
                ),
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: zone,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  hintText: 'UTC',
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
              if (start.text.trim().isEmpty || end.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final freezeStart = start.text.trim();
    final freezeEnd = end.text.trim();
    final cronTimezone = zone.text.trim();
    start.dispose();
    end.dispose();
    zone.dispose();
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .saveFreezePeriod(
            project.id,
            periodId: existing?.id,
            freezeStart: freezeStart,
            freezeEnd: freezeEnd,
            cronTimezone: cronTimezone.isEmpty ? 'UTC' : cronTimezone,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FreezePeriod period,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete deploy freeze?',
      body: '"${period.freezeStart}" to "${period.freezeEnd}" will be removed.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteFreezePeriod(project.id, period.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

/// Pull mirrors with add / toggle / delete.
class RemoteMirrorsSection extends ConsumerWidget {
  const RemoteMirrorsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mirrors = ref.watch(projectRemoteMirrorsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Mirroring repositories')),
            TextButton.icon(
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Sync now'),
              onPressed: () => _syncNow(context, ref),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _add(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: mirrors.when(
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
                      icon: Icons.sync_outlined,
                      title: 'No mirrors',
                    ),
                  )
                : Column(
                    children: [
                      for (final m in list)
                        _RemoteMirrorTile(
                          mirror: m,
                          onToggle: (v) => _toggle(context, ref, m, v),
                          onDelete: () => _delete(context, ref, m),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final url = TextEditingController();
    final regex = TextEditingController();
    var onlyProtected = false;
    var keepDivergent = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mirror repository'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: url,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Git repository URL',
                    hintText: 'https://user:token@example.com/repo.git',
                  ),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: regex,
                  decoration: const InputDecoration(
                    labelText: 'Branch regex (optional)',
                    hintText: r'^(main|release/.*)$',
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Only protected branches'),
                  value: onlyProtected,
                  onChanged: (v) => setState(() => onlyProtected = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Keep divergent refs'),
                  value: keepDivergent,
                  onChanged: (v) => setState(() => keepDivergent = v ?? false),
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
                if (url.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final u = url.text.trim();
    final r = regex.text.trim();
    url.dispose();
    regex.dispose();
    if (ok != true || u.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .addRemoteMirror(
            project.id,
            url: u,
            onlyProtectedBranches: onlyProtected,
            keepDivergentRefs: keepDivergent,
            mirrorBranchRegex: r.isEmpty ? null : r,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    RemoteMirror mirror,
    bool enabled,
  ) async {
    try {
      await ref
          .read(projectAdminActionsProvider)
          .updateRemoteMirror(project.id, mirror.id, enabled: enabled);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectAdminActionsProvider).pullMirrorSync(project.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RemoteMirror mirror,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete mirror?',
      body: 'Syncing from ${mirror.url} will stop.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteRemoteMirror(project.id, mirror.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _RemoteMirrorTile extends StatelessWidget {
  const _RemoteMirrorTile({
    required this.mirror,
    required this.onToggle,
    required this.onDelete,
  });

  final RemoteMirror mirror;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      if (mirror.onlyProtectedBranches) 'protected only',
      if (mirror.keepDivergentRefs) 'keep divergent',
      if (mirror.mirrorBranchRegex != null) mirror.mirrorBranchRegex!,
      if (mirror.lastError != null) 'error: ${mirror.lastError}',
      if (mirror.lastUpdateAt != null)
        'synced ${Format.dateTime(mirror.lastUpdateAt)}',
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.sync_outlined, size: 18),
      title: Text(
        mirror.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mirror.lastError != null ? colors.danger : null,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: mirror.enabled, onChanged: onToggle),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _FreezePeriodTile extends StatelessWidget {
  const _FreezePeriodTile({
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  final FreezePeriod period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.ac_unit_outlined, size: 18),
      title: Text(
        '${period.freezeStart} → ${period.freezeEnd}',
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5),
      ),
      subtitle: Text(period.cronTimezone),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
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
