import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/widgets/deploy_tokens_section.dart' as core;
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';

/// Deploy tokens bound to this project's providers.
class DeployTokensSection extends ConsumerWidget {
  const DeployTokensSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return core.DeployTokensSection(
      tokens: ref.watch(projectDeployTokensProvider(project.id)),
      onCreate: (draft) => ref
          .read(projectAdminActionsProvider)
          .addDeployToken(
            project.id,
            name: draft.name,
            scopes: draft.scopes,
            username: draft.username,
            expiresAt: draft.expiresAt,
          ),
      onRevoke: (t) => ref
          .read(projectAdminActionsProvider)
          .deleteDeployToken(project.id, t.id),
      onRetry: () => ref.invalidate(projectDeployTokensProvider(project.id)),
    );
  }
}
