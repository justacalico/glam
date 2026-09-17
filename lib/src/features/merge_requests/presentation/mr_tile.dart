import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// One MR row: state icon, title, source → target, pipeline status.
class MrTile extends StatelessWidget {
  const MrTile({required this.mr, this.onTap, super.key});

  final MergeRequest mr;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final (icon, color) = switch (mr.state) {
      'merged' => (Icons.merge, colors.merged),
      'closed' => (Icons.close, colors.danger),
      _ => (Icons.merge_type, colors.success),
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (mr.draft)
                        Text(
                          'Draft: ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          mr.title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${mr.references ?? '!${mr.iid}'}'
                    ' · ${mr.author?.name ?? 'unknown'}'
                    ' · ${Format.relative(mr.createdAt)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Insets.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mr.sourceBranch,
                          style: const TextStyle(
                            fontFamily: GlamFonts.mono,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.xs,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: colors.inkFaint,
                        ),
                      ),
                      Text(
                        mr.targetBranch,
                        style: TextStyle(
                          fontFamily: GlamFonts.mono,
                          fontSize: 11.5,
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (mr.reviewers.isNotEmpty)
                  AvatarStack(users: mr.reviewers, radius: 9)
                else if (mr.assignees.isNotEmpty)
                  AvatarStack(users: mr.assignees, radius: 9),
                const SizedBox(height: Insets.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mr.headPipeline?.status != null)
                      _PipelineDot(status: mr.headPipeline!.status!),
                    if (mr.userNotesCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: Insets.sm),
                        child: Text(
                          '${mr.userNotesCount}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineDot extends StatelessWidget {
  const _PipelineDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (status) {
      'success' => colors.success,
      'running' => colors.info,
      'failed' => colors.danger,
      'pending' => colors.warning,
      _ => colors.inkFaint,
    };
    return Icon(Icons.circle, size: 9, color: color);
  }
}
