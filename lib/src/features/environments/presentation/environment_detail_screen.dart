import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/domain/environment.dart';

/// One environment: metadata header + the deployments it has seen.
class EnvironmentDetailScreen extends ConsumerWidget {
  const EnvironmentDetailScreen({required this.loc, super.key});

  final EnvironmentRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(environmentProvider(loc));

    return Scaffold(
      appBar: AppBar(
        title: env.maybeWhen(
          data: (e) => Text(e.name),
          orElse: () => const Text('Environment'),
        ),
        actions: [
          env.maybeWhen(
            data: (e) => _EnvActions(env: e, loc: loc),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<GlEnvironment>(
        value: env,
        onRetry: () => ref.invalidate(environmentProvider(loc)),
        data: (e) => _EnvBody(env: e, loc: loc),
      ),
    );
  }
}

class _EnvActions extends ConsumerWidget {
  const _EnvActions({required this.env, required this.loc});

  final GlEnvironment env;
  final EnvironmentRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        final repo = ref.read(environmentsRepositoryProvider);
        switch (action) {
          case 'stop':
            await repo.stop(loc.project, env.id);
            ref.invalidate(environmentProvider(loc));
          case 'delete':
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete ${env.name}?'),
                content: const Text('Stopped environments can be deleted.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await repo.destroy(loc.project, env.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          case 'open':
            if (env.externalUrl != null) {
              unawaited(launchExternal(env.externalUrl!));
            }
          case 'copy':
            if (env.externalUrl != null) {
              unawaited(
                Clipboard.setData(ClipboardData(text: env.externalUrl!)),
              );
            }
        }
      },
      itemBuilder: (context) => [
        if (env.isAvailable)
          const PopupMenuItem(value: 'stop', child: Text('Stop')),
        if (env.externalUrl != null)
          const PopupMenuItem(value: 'open', child: Text('Open live URL')),
        if (env.externalUrl != null)
          const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
        if (!env.isAvailable)
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _EnvBody extends StatelessWidget {
  const _EnvBody({required this.env, required this.loc});

  final GlEnvironment env;
  final EnvironmentRef loc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Insets.pagePadding.copyWith(bottom: Insets.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StateChip(
                    label: env.state,
                    tone: env.isAvailable ? ChipTone.success : ChipTone.neutral,
                  ),
                  if (env.lastDeployment?.status != null) ...[
                    const SizedBox(width: Insets.sm),
                    StateChip.pipeline(env.lastDeployment!.status!),
                  ],
                ],
              ),
              if (env.externalUrl != null) ...[
                const SizedBox(height: Insets.sm),
                Text(
                  env.externalUrl!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.accent,
                  ),
                ),
              ],
              const SizedBox(height: Insets.md),
              Text('Deployments', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(child: _DeploymentsList(loc: loc)),
      ],
    );
  }
}

class _DeploymentsList extends ConsumerWidget {
  const _DeploymentsList({required this.loc});

  final EnvironmentRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deploymentsProvider(loc));
    final notifier = ref.read(deploymentsProvider(loc).notifier);
    final colors = context.colors;

    return AsyncValueWidget(
      value: list,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.only(bottom: Insets.xl),
        separator: Divider(height: 1, color: colors.border),
        empty: const EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: 'No deployments yet',
        ),
        itemBuilder: (context, index) =>
            _DeploymentTile(deployment: data.items[index]),
      ),
    );
  }
}

class _DeploymentTile extends StatelessWidget {
  const _DeploymentTile({required this.deployment});

  final Deployment deployment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: UserAvatar(
        name: deployment.user?.name ?? '?',
        avatarUrl: deployment.user?.avatarUrl,
        radius: 14,
      ),
      title: Row(
        children: [
          Text('#${deployment.iid}', style: theme.textTheme.titleSmall),
          const SizedBox(width: Insets.sm),
          if (deployment.status != null) StateChip.pipeline(deployment.status!),
        ],
      ),
      subtitle: Text(
        [
          if (deployment.ref != null) deployment.ref!,
          if (deployment.sha != null) deployment.sha!.substring(0, 7),
          if (deployment.deployableName != null) deployment.deployableName!,
          Format.relative(deployment.createdAt),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
