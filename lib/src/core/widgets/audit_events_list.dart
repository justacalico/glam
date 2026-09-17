import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/core/models/audit_event.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';

/// Lists audit events for a project or group scope. Shows a friendly
/// note when the instance or tier doesn't expose the endpoint.
class AuditEventsList extends StatelessWidget {
  const AuditEventsList({required this.events, super.key});

  final AsyncValue<List<AuditEvent>> events;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AsyncValueWidget(
      value: events,
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'No audit events',
            message: 'Audit events may require a paid tier.',
          );
        }
        return Column(
          children: [
            for (final e in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history, size: 18, color: colors.inkMuted),
                title: Text(
                  '${e.authorName ?? 'Someone'} ${e.change ?? 'made a change'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (e.targetDetails?.isNotEmpty ?? false) e.targetDetails,
                    if (e.ipAddress?.isNotEmpty ?? false) e.ipAddress,
                    if (e.createdAt != null) Format.relative(e.createdAt),
                  ].join(' · '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ),
          ],
        );
      },
    );
  }
}
