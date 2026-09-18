import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/extensions.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/icon_text.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// A project row: avatar, name, description, and a stats line.
class ProjectTile extends StatelessWidget {
  const ProjectTile({required this.project, this.onTap, super.key});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'project-avatar-${project.id}',
              child: _ProjectAvatar(project: project),
            ),
            SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.displayName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.archived)
                        _Badge(
                          text: context.l10n.archived,
                          color: colors.warning,
                        ),
                      if (project.visibility == 'private')
                        Padding(
                          padding: const EdgeInsets.only(left: Insets.xs),
                          child: Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: colors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                  if (project.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: Insets.xs),
                    Text(
                      project.description!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: Insets.lg,
                    runSpacing: Insets.xs,
                    children: [
                      IconText(
                        icon: Icons.star_outline,
                        text: Format.compact(project.starCount),
                      ),
                      IconText(
                        icon: Icons.fork_right,
                        text: Format.compact(project.forksCount),
                      ),
                      if (project.openIssuesCount > 0)
                        IconText(
                          icon: Icons.adjust,
                          text: Format.compact(project.openIssuesCount),
                        ),
                      IconText(
                        icon: Icons.schedule,
                        text: Format.relative(project.lastActivityAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectAvatar extends StatelessWidget {
  const _ProjectAvatar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = project.avatarUrl;
    Widget fallback() => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: Radii.borderMd,
      ),
      alignment: Alignment.center,
      child: Text(
        project.name.initials,
        style: TextStyle(
          color: colors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
    if (url == null || url.isEmpty) {
      return fallback();
    }
    return ClipRRect(
      borderRadius: Radii.borderMd,
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: Insets.sm),
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.borderPill,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
