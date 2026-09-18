import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/diff_parser.dart';
import 'package:glam/src/core/widgets/diff_viewer.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// A list of changed files with a +/− summary and expandable per-file diffs.
/// Shared by commit detail and the compare screen.
class ChangesList extends StatelessWidget {
  const ChangesList({required this.changes, this.onLineTap, super.key});

  final List<ChangeEntry> changes;

  /// Called when a diff line is tapped (for line comments). Null hides
  /// the affordance entirely.
  final void Function(ChangeEntry change, DiffLine line)? onLineTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    var additions = 0;
    var deletions = 0;
    final parsed = <(ChangeEntry, FileDiff)>[];
    for (final change in changes) {
      final diff = FileDiff(
        oldPath: change.oldPath,
        newPath: change.newPath,
        hunks: DiffParser.parse(change.diff),
        newFile: change.newFile,
        deletedFile: change.deletedFile,
        renamedFile: change.renamedFile,
      );
      additions += diff.additions;
      deletions += diff.deletions;
      parsed.add((change, diff));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.storageStatPair(
                parsed.length,
                parsed.length == 1
                    ? context.l10n.fileSingular
                    : context.l10n.filePlural,
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: Insets.md),
            Text(
              context.l10n.moreCount(additions),
              style: TextStyle(color: colors.diffAdd),
            ),
            const SizedBox(width: Insets.xs),
            Text(
              context.l10n.deletionsMinus(deletions),
              style: TextStyle(color: colors.diffRemove),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        for (final (change, diff) in parsed) ...[
          _FileChangeTile(
            key: ValueKey(change.displayPath),
            change: change,
            diff: diff,
            onLineTap: onLineTap,
          ),
          const SizedBox(height: Insets.md),
        ],
      ],
    );
  }
}

class _FileChangeTile extends StatefulWidget {
  const _FileChangeTile({
    required this.change,
    required this.diff,
    this.onLineTap,
    super.key,
  });

  final ChangeEntry change;
  final FileDiff diff;
  final void Function(ChangeEntry change, DiffLine line)? onLineTap;

  @override
  State<_FileChangeTile> createState() => _FileChangeTileState();
}

class _FileChangeTileState extends State<_FileChangeTile> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final change = widget.change;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Row(
                children: [
                  Icon(
                    change.deletedFile
                        ? Icons.remove_circle_outline
                        : change.newFile
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    size: 15,
                    color: change.deletedFile
                        ? colors.danger
                        : change.newFile
                        ? colors.success
                        : colors.inkMuted,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      change.displayPath,
                      style: const TextStyle(
                        fontFamily: GlamFonts.mono,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    context.l10n.diffStats(
                      widget.diff.additions,
                      widget.diff.deletions,
                    ),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: Insets.sm),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            if (widget.diff.hunks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Text(
                  context.l10n.diffTooLargeOrBinaryView,
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200,
                    child: DiffViewer(
                      diff: widget.diff,
                      onLineTap: widget.onLineTap == null
                          ? null
                          : (line) => widget.onLineTap!(widget.change, line),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
