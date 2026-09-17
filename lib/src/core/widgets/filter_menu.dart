import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';

/// Compact dropdown filter for a single-valued string dimension
/// (label, milestone, ...). First entry clears the filter.
class FilterMenu extends StatelessWidget {
  const FilterMenu({
    required this.title,
    required this.current,
    required this.options,
    required this.onSelect,
    this.labels = const {},
    super.key,
  });

  final String title;
  final String? current;
  final List<String> options;
  final ValueChanged<String?> onSelect;

  /// Optional display labels when option values aren't user-facing
  /// (e.g. `yes`/`no` API params).
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<String?>(
      tooltip: 'Filter by $title',
      onSelected: onSelect,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: null,
          checked: current == null,
          child: Text('Any $title'),
        ),
        for (final o in options)
          CheckedPopupMenuItem(
            value: o,
            checked: current == o,
            child: Text(labels[o] ?? o),
          ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: Radii.borderMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labels[current] ?? current ?? title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: Insets.xs),
            Icon(Icons.expand_more, size: 16, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
