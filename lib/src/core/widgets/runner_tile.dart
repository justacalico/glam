import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/features/projects/domain/runner.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Status-dotted runner row shared by the project runners section and
/// the group Runners tab.
class RunnerTile extends StatelessWidget {
  const RunnerTile({required this.runner, this.trailing, super.key});

  final Runner runner;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dotColor = runner.paused
        ? colors.inkFaint
        : switch (runner.status) {
            'online' => colors.success,
            'offline' || 'stale' => colors.danger,
            _ => colors.inkFaint,
          };
    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 10, color: dotColor),
      title: Text(
        runner.description.isEmpty
            ? context.l10n.runnerId(runner.id)
            : runner.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          context.l10n.runnerStatus(runner.status),
          runner.typeLabel,
          if (runner.tagList.isNotEmpty) runner.tagList.join(', '),
        ].join(' · '),
      ),
      trailing: trailing,
    );
  }
}
