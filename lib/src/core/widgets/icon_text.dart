import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';

/// Small `icon + label` row used for metadata (author, dates, counts).
class IconText extends StatelessWidget {
  const IconText({
    required this.icon,
    required this.text,
    this.color,
    this.mono = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? color;

  /// Render the text in JetBrains Mono (SHAs, paths).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effective = color ?? colors.inkMuted;
    final style = mono
        ? TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: effective,
          )
        : Theme.of(context).textTheme.labelMedium!.copyWith(color: effective);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effective),
        const SizedBox(width: Insets.xs),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
