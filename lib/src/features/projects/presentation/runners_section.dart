import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/runner_tile.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/runner.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// CI/CD runners: shared/group enablement switches plus the runners
/// available to this project. Only project-type runners can be removed
/// here — shared and group runners follow the switches above.
class RunnersSection extends ConsumerWidget {
  const RunnersSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final runners = ref.watch(projectRunnersProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Runners'),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                dense: true,
                title: const Text('Shared runners'),
                subtitle: const Text('Allow instance runners to pick up jobs'),
                value: project.sharedRunnersEnabled,
                onChanged: (v) =>
                    _setFlags(context, ref, sharedRunnersEnabled: v),
              ),
              Divider(height: 1, color: colors.border, indent: Insets.lg),
              SwitchListTile(
                dense: true,
                title: const Text('Group runners'),
                subtitle: const Text('Allow group runners to pick up jobs'),
                value: project.groupRunnersEnabled,
                onChanged: (v) =>
                    _setFlags(context, ref, groupRunnersEnabled: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: runners.when(
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
                      icon: Icons.smart_toy_outlined,
                      title: 'No runners available',
                    ),
                  )
                : Column(
                    children: [
                      for (final r in list)
                        RunnerTile(
                          runner: r,
                          trailing: r.isProjectRunner
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                  ),
                                  tooltip: 'Remove from project',
                                  onPressed: () => _disable(context, ref, r),
                                )
                              : null,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _setFlags(
    BuildContext context,
    WidgetRef ref, {
    bool? sharedRunnersEnabled,
    bool? groupRunnersEnabled,
  }) async {
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateProject(
            project.id,
            sharedRunnersEnabled: sharedRunnersEnabled,
            groupRunnersEnabled: groupRunnersEnabled,
          );
      ref
        ..invalidate(projectProvider(project.id.toString()))
        ..invalidate(projectRunnersProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _disable(BuildContext context, WidgetRef ref, Runner r) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Remove runner?',
      body:
          '"${r.name.isEmpty ? r.description : r.name}" will stop '
          "running this project's jobs.",
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .disableRunner(project.id, r.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}
