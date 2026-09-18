import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// One issue row: state dot, title, labels, and metadata.
class IssueTile extends StatelessWidget {
  const IssueTile({required this.issue, this.onTap, super.key});

  final Issue issue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final open = issue.isOpen;

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
              child: Icon(
                open ? Icons.circle_outlined : Icons.check_circle,
                size: 17,
                color: open ? colors.success : colors.info,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${issue.references ?? '#${issue.iid}'}'
                    ' · ${issue.author?.name ?? 'unknown'}'
                    ' · ${Format.relative(issue.createdAt)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (issue.labels.isNotEmpty) ...[
                    const SizedBox(height: Insets.sm),
                    Wrap(
                      spacing: Insets.xs,
                      runSpacing: Insets.xs,
                      children: [
                        for (final label in issue.labels.take(4))
                          LabelChip(name: label),
                        if (issue.labels.length > 4)
                          Text(
                            context.l10n.moreCount(issue.labels.length - 4),
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (issue.assignees.isNotEmpty)
                  AvatarStack(users: issue.assignees, radius: 9),
                const SizedBox(height: Insets.xs),
                if (issue.userNotesCount > 0)
                  _Meta(
                    icon: Icons.mode_comment_outlined,
                    text: '${issue.userNotesCount}',
                  ),
                if (issue.taskStatus != null)
                  _Meta(icon: Icons.checklist, text: issue.taskStatus!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.inkFaint),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 11.5, color: colors.inkFaint)),
        ],
      ),
    );
  }
}
