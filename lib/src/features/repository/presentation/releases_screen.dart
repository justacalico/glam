import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// Release list; each entry expands to show notes and asset links.
class ReleasesScreen extends ConsumerWidget {
  const ReleasesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(releasesProvider(projectId));
    final notifier = ref.read(releasesProvider(projectId).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.sm,
              Insets.md,
              0,
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New release'),
              onPressed: () => _showCreate(context, ref),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: state,
            onRetry: notifier.refresh,
            data: (data) => PagedListView(
              state: data,
              onLoadMore: notifier.loadMore,
              onRefresh: notifier.refresh,
              padding: Insets.pagePadding,
              separator: const SizedBox(height: Insets.md),
              empty: const EmptyState(
                icon: Icons.new_releases_outlined,
                title: 'No releases yet',
              ),
              itemBuilder: (context, index) => _ReleaseCard(
                projectId: projectId,
                release: data.items[index],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final tag = TextEditingController();
    final name = TextEditingController();
    final description = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New release'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tag,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tag (new or existing)',
              ),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Release name'),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: description,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Release notes',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (saved == true && tag.text.trim().isNotEmpty) {
      await ref
          .read(repositoryRepositoryProvider)
          .createRelease(
            projectId,
            tag: tag.text.trim(),
            name: name.text.trim().isEmpty ? tag.text.trim() : name.text.trim(),
            description: description.text.isEmpty
                ? null
                : description.text.trim(),
          );
      ref.invalidate(releasesProvider);
    }
  }
}

class _ReleaseCard extends ConsumerStatefulWidget {
  const _ReleaseCard({required this.projectId, required this.release});

  final String projectId;
  final Release release;

  @override
  ConsumerState<_ReleaseCard> createState() => _ReleaseCardState();
}

class _ReleaseCardState extends ConsumerState<_ReleaseCard> {
  var _expanded = false;

  Future<void> _showEdit() async {
    final release = widget.release;
    final name = TextEditingController(text: release.name ?? '');
    final description = TextEditingController(text: release.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${release.tagName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Release name'),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: description,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Release notes',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(repositoryRepositoryProvider)
          .updateRelease(
            widget.projectId,
            release.tagName,
            name: name.text.trim(),
            description: description.text.trim(),
          );
      ref.invalidate(releasesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.release.tagName}?'),
        content: const Text('The release is removed; the tag stays.'),
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
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(repositoryRepositoryProvider)
          .deleteRelease(widget.projectId, widget.release.tagName);
      ref.invalidate(releasesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editLink(ReleaseLink? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final url = TextEditingController(text: existing?.url ?? '');
    final filepath = TextEditingController(text: existing?.filepath ?? '');
    var linkType = existing?.linkType ?? 'other';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add asset link' : 'Edit link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: Insets.md),
              DropdownButtonFormField<String>(
                initialValue: linkType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'runbook', child: Text('Runbook')),
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'package', child: Text('Package')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => linkType = v ?? 'other'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: filepath,
                decoration: const InputDecoration(
                  labelText: 'Filepath (optional)',
                  hintText: '/releases/v1.2.0/asset.zip',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    try {
      final repo = ref.read(repositoryRepositoryProvider);
      final tag = widget.release.tagName;
      final trimmedUrl = url.text.trim();
      if (existing == null) {
        await repo.createReleaseLink(
          widget.projectId,
          tag,
          name: name.text.trim(),
          url: trimmedUrl,
          linkType: linkType,
          filepath: filepath.text.trim().isEmpty ? null : filepath.text.trim(),
        );
      } else {
        await repo.updateReleaseLink(
          widget.projectId,
          tag,
          existing.id!,
          name: name.text.trim(),
          url: trimmedUrl,
          linkType: linkType,
          filepath: filepath.text.trim().isEmpty ? null : filepath.text.trim(),
        );
      }
      ref.invalidate(releasesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteLink(ReleaseLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${link.name}?'),
        content: const Text('Only the link is removed; assets stay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(repositoryRepositoryProvider)
          .deleteReleaseLink(
            widget.projectId,
            widget.release.tagName,
            link.id!,
          );
      ref.invalidate(releasesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showEvidence() async {
    try {
      final ev = await ref
          .read(repositoryRepositoryProvider)
          .releaseEvidence(widget.projectId, widget.release.tagName);
      if (!mounted) {
        return;
      }
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Evidence · ${widget.release.tagName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHA: ${ev.sha ?? '—'}'),
                const SizedBox(height: Insets.sm),
                Text('File: ${ev.filepath ?? '—'}'),
                const SizedBox(height: Insets.sm),
                Text('Collected: ${Format.dateTime(ev.collectedAt)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 404 ? 'No evidence collected' : e.message,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final release = widget.release;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: Radii.borderMd,
            child: Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: Radii.borderMd,
                    ),
                    child: Icon(
                      Icons.new_releases_outlined,
                      color: colors.accent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          release.name ?? release.tagName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${release.tagName} · '
                          '${Format.date(release.releasedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Release actions',
                    iconSize: 18,
                    icon: Icon(Icons.more_vert, color: colors.inkFaint),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'evidence', child: Text('Evidence')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') {
                        unawaited(_showEdit());
                      } else if (v == 'evidence') {
                        unawaited(_showEvidence());
                      } else if (v == 'delete') {
                        unawaited(_confirmDelete());
                      }
                    },
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (release.description?.isNotEmpty ?? false)
                    MarkdownViewer(data: release.description!),
                  if (release.author != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.md),
                      child: Text(
                        'by ${release.author!.name}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: Insets.md),
                  for (final link in release.assets)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: colors.accent,
                          ),
                          const SizedBox(width: Insets.sm),
                          Expanded(
                            child: InkWell(
                              onTap: () => launchExternal(link.url),
                              child: Text(
                                link.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                          if (link.linkType != null)
                            Padding(
                              padding: const EdgeInsets.only(right: Insets.sm),
                              child: Text(
                                link.linkType!,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          if (link.id != null)
                            PopupMenuButton<String>(
                              iconSize: 16,
                              icon: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: colors.inkFaint,
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit link'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Remove link'),
                                ),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') {
                                  unawaited(_editLink(link));
                                } else if (v == 'delete') {
                                  unawaited(_deleteLink(link));
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_link, size: 16),
                      label: const Text('Add link'),
                      onPressed: () => unawaited(_editLink(null)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
