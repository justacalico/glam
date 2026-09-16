import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';

/// One comment in an issue/MR thread.
class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, this.footer, super.key});

  final Note note;

  /// Optional row under the body, e.g. emoji reactions.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.md - 1),
              ),
            ),
            child: Row(
              children: [
                if (note.author != null)
                  UserAvatar(
                    name: note.author!.name,
                    avatarUrl: note.author!.avatarUrl,
                    radius: 9,
                  ),
                const SizedBox(width: Insets.sm),
                Text(
                  note.author?.name ?? 'deleted user',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  Format.relative(note.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: MarkdownViewer(data: note.body),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                0,
                Insets.md,
                Insets.sm,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
