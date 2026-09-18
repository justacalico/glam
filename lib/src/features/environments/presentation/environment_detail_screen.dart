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
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/data/environments_repository.dart';
import 'package:glam/src/features/environments/domain/environment.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
          orElse: () => Text(context.l10n.environment),
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    EnvironmentsRepository repo,
  ) async {
    final name = TextEditingController(text: env.name);
    final url = TextEditingController(text: env.externalUrl ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.editEnvironment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.fieldName),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: url,
              decoration: InputDecoration(
                labelText: context.l10n.externalUrlOptional,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await repo.updateEnvironment(
        loc.project,
        env.id,
        name: name.text.trim(),
        externalUrl: url.text.trim().isEmpty ? null : url.text.trim(),
      );
      ref.invalidate(environmentProvider(loc));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        final repo = ref.read(environmentsRepositoryProvider);
        switch (action) {
          case 'edit':
            await _edit(context, ref, repo);
          case 'stop':
            await repo.stop(loc.project, env.id);
            ref.invalidate(environmentProvider(loc));
          case 'delete':
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.deleteNamedConfirm(env.name)),
                content: Text(context.l10n.stoppedEnvironmentsCanBeDeleted),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.actionCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.actionDelete),
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
        PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
        if (env.isAvailable)
          PopupMenuItem(value: 'stop', child: Text(context.l10n.stop)),
        if (env.externalUrl != null)
          PopupMenuItem(value: 'open', child: Text(context.l10n.openLiveUrl)),
        if (env.externalUrl != null)
          PopupMenuItem(value: 'copy', child: Text(context.l10n.copyUrl)),
        if (!env.isAvailable)
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.actionDelete),
          ),
      ],
    );
  }
}

class _EnvBody extends StatefulWidget {
  const _EnvBody({required this.env, required this.loc});

  final GlEnvironment env;
  final EnvironmentRef loc;

  @override
  State<_EnvBody> createState() => _EnvBodyState();
}

class _EnvBodyState extends State<_EnvBody> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final env = widget.env;
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
              Row(
                children: [
                  Text(
                    context.l10n.hookDeployments,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilterMenu(
                    title: context.l10n.status,
                    current: _status,
                    options: const [
                      'created',
                      'running',
                      'success',
                      'failed',
                      'canceled',
                      'blocked',
                    ],
                    onSelect: (s) => setState(() => _status = s),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _DeploymentsList(filter: (env: widget.loc, status: _status)),
        ),
      ],
    );
  }
}

class _DeploymentsList extends ConsumerWidget {
  const _DeploymentsList({required this.filter});

  final DeploymentFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deploymentsProvider(filter));
    final notifier = ref.read(deploymentsProvider(filter).notifier);
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
        empty: EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: context.l10n.noDeploymentsYet,
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
          Text(
            context.l10n.issueIid(deployment.iid),
            style: theme.textTheme.titleSmall,
          ),
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
