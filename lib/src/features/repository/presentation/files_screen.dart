import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/repository/presentation/file_editor_screen.dart';

/// Repository file browser: folder listing with a breadcrumb and a
/// branch/ref selector.
class FilesScreen extends ConsumerWidget {
  const FilesScreen({
    required this.projectId,
    this.defaultRef,
    this.path,
    super.key,
  });

  final String projectId;
  final String? defaultRef;
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentRef = defaultRef;
    final location = (
      project: projectId as Object,
      ref: currentRef,
      path: path,
    );
    final state = ref.watch(treeProvider(location));
    final notifier = ref.read(treeProvider(location).notifier);

    return Column(
      children: [
        _PathBar(projectId: projectId, ref: currentRef, path: path),
        Divider(height: 1, color: colors.border),
        Expanded(
          child: AsyncValueWidget(
            value: state,
            onRetry: notifier.refresh,
            data: (data) {
              final sorted = sortTreeEntries(data.items);
              return PagedListView(
                state: data,
                onLoadMore: notifier.loadMore,
                onRefresh: notifier.refresh,
                padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                empty: const EmptyState(
                  icon: Icons.folder_open,
                  title: 'Empty directory',
                ),
                itemBuilder: (context, index) => _TreeTile(
                  entry: sorted[index],
                  onTap: () => _open(context, sorted[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, TreeEntry entry) {
    if (entry.isDirectory) {
      unawaited(
        context.push(
          Routes.projectTree(projectId, ref: defaultRef, path: entry.path),
        ),
      );
    } else if (!entry.isSubmodule) {
      unawaited(
        context.push(
          Routes.projectBlob(projectId, ref: defaultRef, path: entry.path),
        ),
      );
    }
  }
}

class _PathBar extends ConsumerWidget {
  const _PathBar({
    required this.projectId,
    required this.ref,
    required this.path,
  });

  final String projectId;
  final String? ref;
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef refScope) {
    final colors = context.colors;
    final segments = path?.split('/') ?? <String>[];

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: Insets.sm),
          _RefPicker(projectId: projectId, currentRef: ref),
          const SizedBox(width: Insets.xs),
          VerticalDivider(width: 1, color: colors.border),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
              children: [
                _Crumb(
                  label: '/',
                  onTap: path == null
                      ? null
                      : () =>
                            context.go(Routes.projectTree(projectId, ref: ref)),
                ),
                for (var i = 0; i < segments.length; i++)
                  _Crumb(
                    label: segments[i],
                    last: i == segments.length - 1,
                    onTap: () => context.go(
                      Routes.projectTree(
                        projectId,
                        ref: ref,
                        path: segments.sublist(0, i + 1).join('/'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (ref != null)
            IconButton(
              tooltip: 'New file',
              icon: Icon(Icons.add, size: 18, color: colors.inkMuted),
              onPressed: () async {
                final committed = await FileEditorScreen.show(
                  context,
                  projectId: projectId,
                  branch: ref!,
                  pathPrefix: path == null ? '' : '$path/',
                );
                if (committed == true) {
                  refScope.invalidate(
                    treeProvider((project: projectId, ref: ref, path: path)),
                  );
                }
              },
            ),
          const SizedBox(width: Insets.sm),
        ],
      ),
    );
  }
}

class _RefPicker extends ConsumerWidget {
  const _RefPicker({required this.projectId, required this.currentRef});

  final String projectId;
  final String? currentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final branches = ref.watch(branchesProvider(projectId));
    final names =
        branches.value?.items.map((b) => b.name).toList() ??
        (currentRef == null ? <String>[] : [currentRef!]);

    return PopupMenuButton<String>(
      tooltip: 'Switch branch',
      onSelected: (name) =>
          context.go(Routes.projectTree(projectId, ref: name)),
      itemBuilder: (context) => [
        for (final name in names)
          PopupMenuItem(
            value: name,
            child: Row(
              children: [
                if (name == currentRef)
                  Icon(Icons.check, size: 16, color: colors.accent)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: Insets.sm),
                Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: Radii.borderSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, size: 14, color: colors.inkMuted),
            const SizedBox(width: Insets.xs),
            Text(
              currentRef ?? '—',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: colors.ink,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, this.onTap, this.last = false});

  final String label;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: last ? colors.ink : colors.inkMuted,
      fontFamily: 'JetBrains Mono',
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: Radii.borderSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.xs,
              vertical: Insets.sm,
            ),
            child: Text(label, style: style),
          ),
        ),
        if (!last) Icon(Icons.chevron_right, size: 14, color: colors.inkFaint),
      ],
    );
  }
}

class _TreeTile extends StatelessWidget {
  const _TreeTile({required this.entry, this.onTap});

  final TreeEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = switch (entry.type) {
      'tree' => Icons.folder_outlined,
      'commit' => Icons.inventory_2_outlined,
      _ => _fileIcon(entry.name),
    };
    final iconColor = entry.isDirectory ? colors.info : colors.inkMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md - 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.isSubmodule)
              Icon(Icons.link, size: 14, color: colors.inkFaint)
            else
              Icon(Icons.chevron_right, size: 16, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String name) {
    return switch (name.split('.').last.toLowerCase()) {
      'png' ||
      'jpg' ||
      'jpeg' ||
      'gif' ||
      'svg' ||
      'webp' => Icons.image_outlined,
      'md' || 'markdown' => Icons.article_outlined,
      'json' || 'yaml' || 'yml' || 'toml' || 'xml' => Icons.data_object,
      'lock' => Icons.lock_outline,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}
