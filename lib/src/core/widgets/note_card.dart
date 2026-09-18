import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// One comment in an issue/MR thread.
class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    this.footer,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Note note;

  /// Optional row under the body, e.g. emoji reactions.
  final Widget? footer;

  /// Called with the new body after the edit dialog is confirmed.
  final Future<void> Function(String body)? onEdit;

  /// Called after the delete confirm dialog is accepted.
  final Future<void> Function()? onDelete;

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
                Expanded(
                  child: Text(
                    Format.relative(note.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: context.l10n.noteActions,
                    iconSize: 16,
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: colors.inkFaint,
                    ),
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.l10n.actionEdit),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.l10n.actionDelete),
                        ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') {
                        unawaited(_promptEdit(context));
                      } else if (v == 'delete') {
                        unawaited(_confirmDelete(context));
                      }
                    },
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

  Future<void> _promptEdit(BuildContext context) async {
    final controller = TextEditingController(text: note.body);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.noteEditTitle),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !context.mounted) {
      return;
    }
    await onEdit!(text);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.noteDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await onDelete!();
    }
  }
}
