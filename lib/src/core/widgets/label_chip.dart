import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/color_parse.dart';

/// A GitLab label rendered as a colored pill. GitLab scoped labels
/// (`scope::value`) are shown with a divider, matching the web UI.
class LabelChip extends StatelessWidget {
  const LabelChip({required this.name, this.color, this.onTap, super.key});

  final String name;

  /// Hex string as returned by the API (`#rrggbb`). Falls back to the
  /// muted surface color.
  final String? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = parseHexColor(color) ?? colors.surfaceMuted;
    final fg = color == null ? colors.inkMuted : contrastingText(bg);

    return Material(
      color: bg,
      borderRadius: Radii.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.borderPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm + 2,
            vertical: Insets.xs - 1,
          ),
          child: Text(
            name,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
