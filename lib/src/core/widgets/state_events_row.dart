import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/resource_state_event.dart';
import 'package:glam/src/core/utils/format.dart';

/// Close/reopen entries for an issue or MR activity stream. Renders
/// nothing while loading, on error, or when the history is empty.
class StateEventsRow extends StatelessWidget {
  const StateEventsRow({required this.events, super.key});

  final AsyncValue<List<ResourceStateEvent>> events;

  @override
  Widget build(BuildContext context) {
    final list = events.value;
    if (list == null || list.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.xs,
      children: [
        for (final e in list)
          Chip(
            avatar: Icon(
              e.state == 'reopened'
                  ? Icons.refresh_outlined
                  : Icons.block_outlined,
              size: 14,
              color: colors.inkFaint,
            ),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: colors.border),
            backgroundColor: colors.surface,
            label: Text(
              '${e.state} '
              '${e.user != null ? 'by ${e.user!.username}' : ''}'
              '${e.createdAt != null ? ' · ' : ''}'
              '${Format.relative(e.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
