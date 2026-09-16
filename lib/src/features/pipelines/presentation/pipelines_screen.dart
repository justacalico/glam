import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';

/// Pipeline history for a project — the CI/CD tab.
class PipelinesScreen extends ConsumerWidget {
  const PipelinesScreen({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(pipelinesProvider(projectId));
    final notifier = ref.read(pipelinesProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: 'No pipelines yet',
        ),
        itemBuilder: (context, index) =>
            PipelineTile(pipeline: data.items[index], projectId: projectId),
      ),
    );
  }
}

/// One pipeline row: status, #id, ref@sha, duration, user.
class PipelineTile extends StatelessWidget {
  const PipelineTile({
    required this.pipeline,
    required this.projectId,
    super.key,
  });

  final Pipeline pipeline;
  final Object projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => unawaited(
        context.push(Routes.projectPipeline(projectId, pipeline.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            StateChip.pipeline(pipeline.status),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${pipeline.iid ?? pipeline.id}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: Insets.sm),
                      Flexible(
                        child: Text(
                          pipeline.ref ?? '',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${pipeline.user?.name ?? 'system'}'
                    ' · ${Format.relative(pipeline.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pipeline.sha == null
                      ? ''
                      : pipeline.sha!.length > 8
                      ? pipeline.sha!.substring(0, 8)
                      : pipeline.sha!,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.5,
                  ),
                ),
                if (pipeline.duration != null)
                  Text(
                    Format.duration(pipeline.duration?.toDouble()),
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
