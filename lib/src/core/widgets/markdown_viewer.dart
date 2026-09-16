import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/url_launcher.dart';

/// Renders GitLab markdown (descriptions, comments, READMEs) with the
/// app's typography. Links open externally.
class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({required this.data, this.padding, super.key});

  final String data;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return MarkdownBody(
      data: data,
      onTapLink: (_, href, _) {
        if (href != null) {
          unawaited(launchExternal(href));
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium,
        h1: theme.textTheme.headlineMedium,
        h2: theme.textTheme.headlineSmall,
        h3: theme.textTheme.titleLarge,
        h4: theme.textTheme.titleMedium,
        h5: theme.textTheme.titleSmall,
        h6: theme.textTheme.titleSmall,
        a: theme.textTheme.bodyMedium!.copyWith(
          color: colors.accent,
          decoration: TextDecoration.underline,
          decorationColor: colors.accent.withValues(alpha: 0.4),
        ),
        code: GlamTypography.mono(
          context,
          size: 13,
        ).copyWith(backgroundColor: colors.codeBackground, color: colors.ink),
        codeblockDecoration: BoxDecoration(
          color: colors.codeBackground,
          borderRadius: Radii.borderMd,
          border: Border.all(color: colors.border),
        ),
        codeblockPadding: const EdgeInsets.all(Insets.md),
        blockquote: theme.textTheme.bodyMedium!.copyWith(
          color: colors.inkMuted,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.accent, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: Insets.md),
        tableHead: theme.textTheme.labelMedium,
        tableBody: theme.textTheme.bodySmall,
        tableBorder: TableBorder.all(color: colors.border),
        tableColumnWidth: const IntrinsicColumnWidth(),
        listBullet: theme.textTheme.bodyMedium,
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        blockSpacing: Insets.md,
      ),
    );
  }
}
