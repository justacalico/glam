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
import 'package:glam/src/core/utils/l10n.dart';

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
                context.l10n.linkedIssues,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.link),
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
                      context.l10n.noLinkedIssues,
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
        builder: (context, setState) {
          void submit() {
            if (int.tryParse(iid.text.trim()) == null) {
              setState(() => iidError = true);
              return;
            }
            Navigator.pop(context, true);
          }

          return AlertDialog(
            title: Text(context.l10n.linkIssue),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: iid,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.issueIidField,
                      errorText: iidError ? 'Enter an issue number' : null,
                    ),
                    onChanged: (_) {
                      if (iidError) {
                        setState(() => iidError = false);
                      }
                    },
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: Insets.sm),
                  TextField(
                    controller: project,
                    decoration: InputDecoration(
                      labelText: context.l10n.projectOptional,
                      hintText: context.l10n.groupOtherProject,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(child: Text(context.l10n.linkType)),
                      DropdownButton<String>(
                        value: linkType,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => linkType = v);
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'relates_to',
                            child: Text(context.l10n.relatesTo),
                          ),
                          DropdownMenuItem(
                            value: 'blocks',
                            child: Text(context.l10n.blocks),
                          ),
                          DropdownMenuItem(
                            value: 'is_blocked_by',
                            child: Text(context.l10n.blockedBy),
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
                child: Text(context.l10n.actionCancel),
              ),
              FilledButton(onPressed: submit, child: Text(context.l10n.link)),
            ],
          );
        },
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeLink),
        content: Text(context.l10n.unlinkP0FromThisIssue(link.issue.iid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionRemove),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
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
    // The tile sits inside a decorated card, so it needs its own
    // Material for the splash to paint on.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        dense: true,
        leading: Icon(
          issue.isOpen ? Icons.adjust : Icons.check_circle_outline,
          size: 18,
          color: issue.isOpen ? context.colors.success : context.colors.merged,
        ),
        title: Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          context.l10n.linkSummary(
            link.typeLabel,
            issue.references ?? context.l10n.issueIid(issue.iid),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => unawaited(
          context.push(Routes.projectIssue(issue.projectId, issue.iid)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.link_off_outlined, size: 18),
          tooltip: context.l10n.removeLinkTooltip,
          onPressed: onRemove,
        ),
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
    final closedBy = ref.watch(issueClosedByMrsProvider(loc)).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.relatedMergeRequests,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (closedBy.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Text(
            context.l10n.willBeClosedBy,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final m in closedBy)
            MrTile(
              mr: m,
              onTap: () =>
                  unawaited(context.push(Routes.projectMr(m.projectId, m.iid))),
            ),
        ],
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
                      context.l10n.noRelatedMergeRequests,
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
