import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/diff_parser.dart';

/// Renders a parsed [FileDiff]: green/red line rows with dual line
/// numbers and `@@` hunk separators.
class DiffViewer extends StatelessWidget {
  const DiffViewer({required this.diff, this.onLineTap, super.key});

  final FileDiff diff;

  /// When set, diff rows become tappable (used for line comments).
  final void Function(DiffLine line)? onLineTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final hunk in diff.hunks) ...[
            _HunkHeader(text: hunk.header),
            for (final line in hunk.lines)
              _DiffRow(line: line, onTap: onLineTap),
          ],
        ],
      ),
    );
  }
}

class _HunkHeader extends StatelessWidget {
  const _HunkHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.xs,
      ),
      color: colors.accentSoft.withValues(alpha: 0.4),
      child: Text(
        text,
        style: GlamTypography.mono(
          context,
          size: 11.5,
        ).copyWith(color: colors.inkMuted),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.line, this.onTap});

  final DiffLine line;
  final void Function(DiffLine line)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, marker) = switch (line.kind) {
      DiffLineKind.added => (colors.diffAddLine, colors.ink, '+'),
      DiffLineKind.removed => (colors.diffRemoveLine, colors.ink, '-'),
      DiffLineKind.context => (Colors.transparent, colors.ink, ' '),
      DiffLineKind.meta => (Colors.transparent, colors.inkFaint, ''),
    };
    final tappable = onTap != null && line.kind != DiffLineKind.meta;
    return InkWell(
      onTap: tappable ? () => onTap!(line) : null,
      child: Container(
        color: bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                line.oldLine?.toString() ?? '',
                textAlign: TextAlign.right,
                style: GlamTypography.mono(
                  context,
                  size: 11,
                ).copyWith(color: colors.inkFaint),
              ),
            ),
            const SizedBox(width: Insets.sm),
            SizedBox(
              width: 36,
              child: Text(
                line.newLine?.toString() ?? '',
                textAlign: TextAlign.right,
                style: GlamTypography.mono(
                  context,
                  size: 11,
                ).copyWith(color: colors.inkFaint),
              ),
            ),
            const SizedBox(width: Insets.sm),
            SizedBox(
              width: 14,
              child: Text(
                marker,
                style: GlamTypography.mono(
                  context,
                  size: 12,
                ).copyWith(color: fg.withValues(alpha: 0.6)),
              ),
            ),
            Expanded(
              child: Text(
                line.content.isEmpty ? ' ' : line.content,
                style: GlamTypography.mono(
                  context,
                  size: 12,
                ).copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
