import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/extensions.dart';

/// Status palette used by [StateChip].
enum ChipTone { success, info, warning, danger, neutral, merged }

/// Small status pill for issues, merge requests, pipelines and jobs.
class StateChip extends StatelessWidget {
  const StateChip({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  /// Pipeline/job status → chip with the right color and icon.
  factory StateChip.pipeline(String status, {Key? key}) {
    final label = status.capitalized;
    final (tone, icon) = switch (status) {
      'success' => (ChipTone.success, Icons.check_circle),
      'running' => (ChipTone.info, Icons.play_circle),
      'failed' => (ChipTone.danger, Icons.error),
      'canceled' || 'canceling' => (ChipTone.neutral, Icons.cancel),
      'pending' => (ChipTone.warning, Icons.schedule),
      'skipped' => (ChipTone.neutral, Icons.skip_next),
      'manual' => (ChipTone.warning, Icons.touch_app),
      _ => (ChipTone.neutral, Icons.more_horiz),
    };
    return StateChip(label: label, tone: tone, icon: icon, key: key);
  }

  /// Issue state chip (`opened`/`closed`).
  factory StateChip.issueState(String state, {Key? key}) {
    return switch (state) {
      'opened' => StateChip(
        label: 'Open',
        tone: ChipTone.success,
        icon: Icons.circle_outlined,
        key: key,
      ),
      'closed' => StateChip(
        label: 'Closed',
        tone: ChipTone.info,
        icon: Icons.check_circle,
        key: key,
      ),
      _ => StateChip(
        label: state.capitalized,
        tone: ChipTone.neutral,
        key: key,
      ),
    };
  }

  /// Merge request state chip (`opened`/`merged`/`closed`/`locked`).
  factory StateChip.mergeRequestState(String state, {Key? key}) {
    return switch (state) {
      'opened' => StateChip(
        label: 'Open',
        tone: ChipTone.success,
        icon: Icons.merge,
        key: key,
      ),
      'merged' => StateChip(
        label: 'Merged',
        tone: ChipTone.merged,
        icon: Icons.merge,
        key: key,
      ),
      'closed' => StateChip(
        label: 'Closed',
        tone: ChipTone.danger,
        icon: Icons.close,
        key: key,
      ),
      'locked' => StateChip(
        label: 'Locked',
        tone: ChipTone.neutral,
        icon: Icons.lock,
        key: key,
      ),
      _ => StateChip(
        label: state.capitalized,
        tone: ChipTone.neutral,
        key: key,
      ),
    };
  }

  final String label;
  final ChipTone tone;
  final IconData? icon;

  Color _color(GlamColors colors) => switch (tone) {
    ChipTone.success => colors.success,
    ChipTone.info => colors.info,
    ChipTone.warning => colors.warning,
    ChipTone.danger => colors.danger,
    ChipTone.merged => colors.merged,
    ChipTone.neutral => colors.inkMuted,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _color(colors);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xs - 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.borderPill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: Insets.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
