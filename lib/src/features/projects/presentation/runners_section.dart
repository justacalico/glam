import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/runner.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// CI/CD runners: assigned runners with unassign, plus available shared
/// runners that can be enabled for the project.
class RunnersSection extends ConsumerWidget {
  const RunnersSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final runners = ref.watch(projectRunnersProvider(project.id));
    final available = ref.watch(projectAvailableRunnersProvider(project.id));

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
                      title: 'No runners enabled',
                    ),
                  )
                : Column(
                    children: [
                      for (final r in list)
                        _RunnerTile(
                          runner: r,
                          trailing: r.runnerType == 'project_type'
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                  ),
                                  tooltip: 'Remove from project',
                                  onPressed: () => _disable(context, ref, r),
                                ),
                        ),
                    ],
                  ),
          ),
        ),
        available.maybeWhen(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Insets.md),
                    Text(
                      'Available shared runners',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: Insets.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: Radii.borderMd,
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          for (final r in list)
                            _RunnerTile(
                              runner: r,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                tooltip: 'Enable for this project',
                                onPressed: () => _enable(context, ref, r),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref, Runner r) async {
    try {
      await ref
          .read(projectAdminActionsProvider)
          .enableRunner(project.id, r.id);
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

class _RunnerTile extends StatelessWidget {
  const _RunnerTile({required this.runner, this.trailing});

  final Runner runner;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dotColor = switch (runner.online) {
      true => colors.success,
      false => colors.danger,
      null => colors.inkFaint,
    };
    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 10, color: dotColor),
      title: Text(
        runner.description.isEmpty
            ? 'Runner #${runner.id}'
            : runner.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          runner.statusLabel,
          runner.typeLabel,
          if (runner.tagList.isNotEmpty) runner.tagList.join(', '),
        ].join(' · '),
      ),
      trailing: trailing,
    );
  }
}
