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
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
            Expanded(child: SectionLabel(context.l10n.protectedBranches)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.protect),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.shield_outlined,
                      title: context.l10n.noProtectedBranches,
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
          title: Text(context.l10n.protectBranch),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.branchOrWildcard,
                    hintText: context.l10n.mainOrRelease,
                  ),
                ),
                SizedBox(height: Insets.md),
                _LevelPicker(
                  label: context.l10n.allowedToPush,
                  value: pushLevel,
                  onChanged: (v) => setState(() => pushLevel = v),
                ),
                _LevelPicker(
                  label: context.l10n.allowedToMerge,
                  value: mergeLevel,
                  onChanged: (v) => setState(() => mergeLevel = v),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(context.l10n.allowForcePush),
                  value: forcePush,
                  onChanged: (v) => setState(() => forcePush = v ?? false),
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
                if (name.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.l10n.protect),
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
      title: context.l10n.unprotectBranch,
      body: context.l10n.p0WillAcceptPushesAgain(b.name),
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
    final push = branch.pushLevels.map(context.l10n.protectedLevel).join(', ');
    final merge = branch.mergeLevels
        .map(context.l10n.protectedLevel)
        .join(', ');
    return ListTile(
      dense: true,
      leading: Icon(
        branch.isWildcard ? Icons.star_outline : Icons.shield_outlined,
        size: 18,
      ),
      title: Text(
        branch.name,
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12.5),
      ),
      subtitle: Text(
        [
          context.l10n.pushP0(push),
          context.l10n.mergeP02(merge),
          if (branch.allowForcePush) context.l10n.forcePushAllowed,
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
          items: [
            DropdownMenuItem(value: 0, child: Text(context.l10n.noOne)),
            DropdownMenuItem(
              value: 30,
              child: Text(context.l10n.developersMaintainers),
            ),
            DropdownMenuItem(value: 40, child: Text(context.l10n.maintainers)),
            DropdownMenuItem(value: 60, child: Text(context.l10n.admins)),
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
            Expanded(child: SectionLabel(context.l10n.protectedTags)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.protect),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.sell_outlined,
                      title: context.l10n.noProtectedTags,
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
          title: Text(context.l10n.protectTag),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.tagOrWildcard,
                    hintText: context.l10n.v100OrV,
                  ),
                ),
                SizedBox(height: Insets.md),
                _LevelPicker(
                  label: context.l10n.allowedToCreate,
                  value: createLevel,
                  onChanged: (v) => setState(() => createLevel = v),
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
                if (name.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.l10n.protect),
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
      title: context.l10n.unprotectTag,
      body: context.l10n.p0CanBeCreatedByAnyone(tag.name),
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
            Expanded(child: SectionLabel(context.l10n.protectedEnvironments)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.protect),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.cloud_outlined,
                      title: context.l10n.noProtectedEnvironments,
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
          title: Text(context.l10n.protectEnvironment),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.environmentOrWildcard,
                    hintText: context.l10n.productionOrReview,
                  ),
                ),
                const SizedBox(height: Insets.md),
                _LevelPicker(
                  label: context.l10n.allowedToDeploy,
                  value: deployLevel,
                  onChanged: (v) => setState(() => deployLevel = v),
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
                if (name.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.l10n.protect),
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
      title: context.l10n.unprotectEnvironment,
      body: context.l10n.p0WillAcceptDeploysAgain(env.name),
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
    final deploy = env.deployLevels.map(context.l10n.protectedLevel).join(', ');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.cloud_outlined, size: 18),
      title: Text(
        env.name,
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12.5),
      ),
      subtitle: Text(context.l10n.deployP0(deploy.isEmpty ? 'none' : deploy)),
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
            Expanded(child: SectionLabel(context.l10n.deployFreezes)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.addFreeze),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.ac_unit_outlined,
                      title: context.l10n.noDeployFreezes,
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
        title: Text(
          existing == null
              ? context.l10n.addDeployFreeze
              : context.l10n.editFreeze,
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: start,
                autofocus: existing == null,
                decoration: InputDecoration(
                  labelText: context.l10n.freezeStartCron,
                  hintText: '0 23 * * 5',
                ),
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: end,
                decoration: InputDecoration(
                  labelText: context.l10n.freezeEndCron,
                  hintText: '0 7 * * 1',
                ),
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: zone,
                decoration: InputDecoration(
                  labelText: context.l10n.timezone,
                  hintText: context.l10n.utc,
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
              if (start.text.trim().isEmpty || end.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(context.l10n.actionSave),
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
      title: context.l10n.deleteDeployFreeze,
      body: context.l10n.p0ToP1WillBeRemoved(
        period.freezeStart,
        period.freezeEnd,
      ),
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
            Expanded(child: SectionLabel(context.l10n.mirroringRepositories)),
            TextButton.icon(
              icon: const Icon(Icons.sync, size: 16),
              label: Text(context.l10n.syncNow),
              onPressed: () => _syncNow(context, ref),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.actionAdd),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.sync_outlined,
                      title: context.l10n.noMirrors,
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
          title: Text(context.l10n.mirrorRepository),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: url,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.gitRepositoryUrl,
                    hintText: 'https://user:token@example.com/repo.git',
                  ),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: regex,
                  decoration: InputDecoration(
                    labelText: context.l10n.branchRegexOptional,
                    hintText: r'^(main|release/.*)$',
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(context.l10n.onlyProtectedBranches),
                  value: onlyProtected,
                  onChanged: (v) => setState(() => onlyProtected = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(context.l10n.keepDivergentRefs),
                  value: keepDivergent,
                  onChanged: (v) => setState(() => keepDivergent = v ?? false),
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
                if (url.text.trim().isEmpty) {
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
      title: context.l10n.deleteMirror,
      body: context.l10n.syncingFromP0WillStop(mirror.url),
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
      if (mirror.onlyProtectedBranches) context.l10n.protectedOnly,
      if (mirror.keepDivergentRefs) context.l10n.keepDivergent,
      if (mirror.mirrorBranchRegex != null) mirror.mirrorBranchRegex!,
      if (mirror.lastError != null) context.l10n.errorP0('${mirror.lastError}'),
      if (mirror.lastUpdateAt != null)
        context.l10n.syncedP0(Format.dateTime(mirror.lastUpdateAt!)),
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.sync_outlined, size: 18),
      title: Text(
        mirror.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12),
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
        context.l10n.branchArrow(period.freezeStart, period.freezeEnd),
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12.5),
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
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12.5),
      ),
      subtitle: Text(context.l10n.createP0(create)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}
