import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/audit_events_list.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Recent audit events on the project. Premium-gated upstream, so the
/// list stays empty on Free tier rather than erroring.
class AuditEventsSection extends ConsumerWidget {
  const AuditEventsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Audit events'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: AuditEventsList(
            events: ref.watch(projectAuditEventsProvider(project.id)),
          ),
        ),
      ],
    );
  }
}
