import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/resource_label_event.dart';
import 'package:glam/src/core/models/resource_milestone_event.dart';
import 'package:glam/src/core/models/resource_state_event.dart';
import 'package:glam/src/core/utils/color_parse.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Close/reopen, milestone, and label entries for an issue or MR
/// activity stream. Renders nothing while loading, on error, or when
/// the history is empty.
class StateEventsRow extends StatelessWidget {
  const StateEventsRow({
    required this.events,
    this.milestoneEvents,
    this.labelEvents,
    super.key,
  });

  final AsyncValue<List<ResourceStateEvent>> events;
  final AsyncValue<List<ResourceMilestoneEvent>>? milestoneEvents;
  final AsyncValue<List<ResourceLabelEvent>>? labelEvents;

  @override
  Widget build(BuildContext context) {
    final list = events.value ?? const <ResourceStateEvent>[];
    final milestones =
        milestoneEvents?.value ?? const <ResourceMilestoneEvent>[];
    final labels = labelEvents?.value ?? const <ResourceLabelEvent>[];
    if (list.isEmpty && milestones.isEmpty && labels.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.xs,
      children: [
        for (final e in list)
          _EventChip(
            icon: e.state == 'reopened'
                ? Icons.refresh_outlined
                : Icons.block_outlined,
            text: context.l10n.stateEventLine(
              e.state == 'reopened'
                  ? context.l10n.eventReopened
                  : context.l10n.stateClosed,
              _by(context, e.user?.username),
              e.createdAt.at(),
            ),
          ),
        for (final e in milestones)
          _EventChip(
            icon: e.action == 'remove' ? Icons.flag_outlined : Icons.flag,
            text: context.l10n.milestoneEventLine(
              e.action == 'remove'
                  ? context.l10n.eventRemoved
                  : context.l10n.eventAdded,
              e.milestoneTitle,
              _by(context, e.user?.username),
              e.createdAt.at(),
            ),
          ),
        for (final e in labels)
          _EventChip(
            icon: Icons.label_outline,
            iconColor: parseHexColor(e.labelColor) ?? colors.inkFaint,
            text: context.l10n.labelEventLine(
              e.action == 'remove'
                  ? context.l10n.eventRemoved
                  : context.l10n.eventAdded,
              e.labelName,
              _by(context, e.user?.username),
              e.createdAt.at(),
            ),
          ),
      ],
    );
  }

  String _by(BuildContext context, String? username) =>
      username == null ? '' : context.l10n.byUser(username);
}

extension on DateTime? {
  String at() => this == null ? '' : '· ${Format.relative(this)}';
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Chip(
      avatar: Icon(icon, size: 14, color: iconColor ?? colors.inkFaint),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colors.border),
      backgroundColor: colors.surface,
      label: Text(text.trim(), style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
