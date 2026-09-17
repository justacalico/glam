import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/domain/issue_link.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';
import 'package:go_router/go_router.dart';

/// Linked issues (relates_to / blocks / blocked_by) with add / remove.
class IssueLinksSection extends ConsumerWidget {
  const IssueLinksSection({required this.loc, super.key});

  final IssueRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final links = ref.watch(issueLinksProvider(loc));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Linked issues',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Link'),
              onPressed: () => _link(context, ref),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: links.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(issueLinksProvider(loc)),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: Text(
                      'No linked issues',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (final l in list)
                        _IssueLinkTile(
                          link: l,
                          onRemove: () => _unlink(context, ref, l),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final iid = TextEditingController();
    final project = TextEditingController();
    var linkType = 'relates_to';
    var iidError = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Link issue'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: iid,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Issue #',
                    errorText: iidError ? 'Enter an issue number' : null,
                  ),
                  onChanged: (_) {
                    if (iidError) {
                      setState(() => iidError = false);
                    }
                  },
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: project,
                  decoration: const InputDecoration(
                    labelText: 'Project (optional)',
                    hintText: 'group/other-project',
                  ),
                ),
                const SizedBox(height: Insets.md),
                Row(
                  children: [
                    const Expanded(child: Text('Link type')),
                    DropdownButton<String>(
                      value: linkType,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => linkType = v);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'relates_to',
                          child: Text('Relates to'),
                        ),
                        DropdownMenuItem(
                          value: 'blocks',
                          child: Text('Blocks'),
                        ),
                        DropdownMenuItem(
                          value: 'is_blocked_by',
                          child: Text('Blocked by'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (int.tryParse(iid.text.trim()) == null) {
                  setState(() => iidError = true);
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
    final draft = (
      iid: int.tryParse(iid.text.trim()),
      project: project.text.trim(),
      type: linkType,
    );
    iid.dispose();
    project.dispose();
    if (ok != true || draft.iid == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(issueLinksProvider(loc).notifier)
          .link(
            draft.project.isEmpty ? loc.project : draft.project,
            draft.iid!,
            draft.type,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    IssueLink link,
  ) async {
    try {
      await ref.read(issueLinksProvider(loc).notifier).unlink(link.linkId);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _IssueLinkTile extends StatelessWidget {
  const _IssueLinkTile({required this.link, required this.onRemove});

  final IssueLink link;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final issue = link.issue;
    return ListTile(
      dense: true,
      leading: Icon(
        issue.isOpen ? Icons.adjust : Icons.check_circle_outline,
        size: 18,
        color: issue.isOpen ? context.colors.success : context.colors.merged,
      ),
      title: Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${link.typeLabel} · ${issue.references ?? '#${issue.iid}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => unawaited(
        context.push(Routes.projectIssue(issue.projectId, issue.iid)),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.link_off_outlined, size: 18),
        tooltip: 'Remove link',
        onPressed: onRemove,
      ),
    );
  }
}

/// Merge requests that mention or close this issue.
class RelatedMrsSection extends ConsumerWidget {
  const RelatedMrsSection({required this.loc, super.key});

  final IssueRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mrs = ref.watch(issueRelatedMrsProvider(loc));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related merge requests',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Insets.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: mrs.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(issueRelatedMrsProvider(loc)),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: Text(
                      'No related merge requests',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (final m in list)
                        MrTile(
                          mr: m,
                          onTap: () => unawaited(
                            context.push(Routes.projectMr(m.projectId, m.iid)),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
