import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/registry/application/registry_providers.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';
import 'package:go_router/go_router.dart';

/// Container repositories published by a project.
class ProjectRegistryTab extends ConsumerWidget {
  const ProjectRegistryTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(containerReposProvider(projectId));
    final notifier = ref.read(containerReposProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView<ContainerRepo>(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(
          icon: Icons.layers_outlined,
          title: 'No container images',
        ),
        itemBuilder: (context, index) {
          final repo = data.items[index];
          return ListTile(
            leading: const Icon(Icons.layers_outlined, size: 20),
            title: Text(
              repo.path,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.5,
              ),
            ),
            subtitle: Text(
              [
                if (repo.tagsCount != null) '${repo.tagsCount} tags',
                if (repo.createdAt != null)
                  'created ${Format.date(repo.createdAt!)}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _delete(context, ref, repo),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
            onTap: () =>
                context.push('/projects/$projectId/registry/${repo.id}'),
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ContainerRepo repo,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete repository?'),
        content: Text('"${repo.path}" and all its tags are removed.'),
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
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(containerReposProvider(projectId).notifier)
          .deleteRepo(repo.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
