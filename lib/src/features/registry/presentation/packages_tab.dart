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

/// Published packages for a project.
class ProjectPackagesTab extends ConsumerWidget {
  const ProjectPackagesTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(projectPackagesProvider(projectId));
    final notifier = ref.read(projectPackagesProvider(projectId).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView<GitLabPackage>(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No packages',
        ),
        itemBuilder: (context, index) {
          final p = data.items[index];
          return ListTile(
            leading: const Icon(Icons.inventory_2_outlined, size: 20),
            title: Text(p.version.isEmpty ? p.name : '${p.name} ${p.version}'),
            subtitle: Text(
              [
                p.packageType,
                if (p.status != 'default') p.status,
                if (p.createdAt != null) Format.date(p.createdAt!),
              ].join(' · '),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _delete(context, ref, p),
            ),
            onTap: () => _files(context, ref, p),
          );
        },
      ),
    );
  }

  Future<void> _files(BuildContext context, WidgetRef ref, GitLabPackage p) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.version.isEmpty ? p.name : '${p.name} ${p.version}'),
        content: SizedBox(
          width: 460,
          child: _PackageFiles(projectId: projectId, pkg: p),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GitLabPackage p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('"${p.name} ${p.version}" is removed permanently.'),
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
          .read(projectPackagesProvider(projectId).notifier)
          .deletePackage(p.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _PackageFiles extends ConsumerWidget {
  const _PackageFiles({required this.projectId, required this.pkg});

  final Object projectId;
  final GitLabPackage pkg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(packageFilesProvider((projectId, pkg.id)));

    return files.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('$e'),
      data: (list) => list.isEmpty
          ? const Text('No files')
          : ListView(
              shrinkWrap: true,
              children: [
                for (final f in list)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                    ),
                    title: Text(
                      f.fileName,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                    trailing: f.size == null
                        ? null
                        : Text(Format.bytes(f.size!)),
                  ),
              ],
            ),
    );
  }
}
