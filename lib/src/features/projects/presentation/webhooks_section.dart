import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/widgets/webhooks_section.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';

/// Project webhooks bound to the project's hooks provider.
class ProjectWebhooksSection extends ConsumerWidget {
  const ProjectWebhooksSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WebhooksSection(
      hooks: ref.watch(projectHooksProvider(project.id)),
      onAdd: (draft) async {
        await ref
            .read(projectAdminActionsProvider)
            .addHook(
              project.id,
              url: draft.url,
              token: draft.token,
              events: draft.events,
              sslVerify: draft.sslVerify,
            );
      },
      onTest: (hook) async {
        await ref
            .read(projectAdminActionsProvider)
            .testHook(project.id, hook.id);
      },
      onDelete: (hook) async {
        await ref
            .read(projectAdminActionsProvider)
            .deleteHook(project.id, hook.id);
      },
    );
  }
}
