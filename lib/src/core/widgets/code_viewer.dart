import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Syntax-highlighted source viewer with line numbers.
class CodeViewer extends StatelessWidget {
  const CodeViewer({
    required this.code,
    this.language,
    this.wrap = false,
    super.key,
  });

  final String code;

  /// Highlight language key (`dart`, `yaml`, ...). Falls back to plain
  /// text when null or unknown.
  final String? language;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? monokaiSublimeTheme : githubTheme;
    final lineCount = '\n'.allMatches(code).length + 1;

    final highlighted = HighlightView(
      code,
      language: language,
      theme: theme,
      padding: const EdgeInsets.all(Insets.md),
      textStyle: GlamTypography.mono(context, size: 12.5),
    );

    final content = wrap
        ? highlighted
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: Insets.md,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  border: Border(right: BorderSide(color: colors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 1; i <= lineCount; i++)
                      Text(
                        '$i',
                        style: GlamTypography.mono(
                          context,
                          size: 12.5,
                        ).copyWith(color: colors.inkFaint),
                      ),
                  ],
                ),
              ),
              highlighted,
            ],
          );

    return Container(
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: wrap
          ? content
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            ),
    );
  }
}
