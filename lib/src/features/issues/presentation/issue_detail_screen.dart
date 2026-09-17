import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/comment_composer.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/note_card.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/engagement/application/engagement_providers.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/presentation/issue_form_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_links_section.dart';

/// Issue detail: metadata, description, and the comment thread with a
/// composer docked at the bottom.
class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({
    required this.projectId,
    required this.iid,
    super.key,
  });

  final Object projectId;
  final int iid;

  IssueRef get _loc => (project: projectId, iid: iid);

  AwardableRef get _awardable =>
      (kind: 'issue', project: projectId, iid: iid, noteId: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(issueProvider(_loc));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text('#$iid'),
        actions: [
          issue.maybeWhen(
            data: (i) => _IssueActions(issue: i, loc: _loc),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<Issue>(
        value: issue,
        onRetry: () => ref.invalidate(issueProvider(_loc)),
        data: (issue) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: Insets.pagePadding,
                children: [
                  _Header(issue: issue),
                  if (issue.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: Insets.lg),
                    Container(
                      padding: const EdgeInsets.all(Insets.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: Radii.borderMd,
                        border: Border.all(color: colors.border),
                      ),
                      child: MarkdownViewer(data: issue.description!),
                    ),
                  ],
                  const SizedBox(height: Insets.md),
                  ReactionsRow(loc: _awardable),
                  const SizedBox(height: Insets.xl),
                  IssueLinksSection(loc: _loc),
                  const SizedBox(height: Insets.xl),
                  RelatedMrsSection(loc: _loc),
                  const SizedBox(height: Insets.xl),
                  Text(
                    'Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.sm),
                  _NotesList(loc: _loc),
                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
            CommentComposer(
              onSend: (body) async {
                await ref
                    .read(issueNotesProvider(_loc).notifier)
                    .addComment(body);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueActions extends ConsumerWidget {
  const _IssueActions({required this.issue, required this.loc});

  final Issue issue;
  final IssueRef loc;

  Future<void> _toggleState(WidgetRef ref) {
    return ref
        .read(issuesRepositoryProvider)
        .updateIssue(
          loc.project,
          loc.iid,
          stateEvent: issue.isOpen ? 'close' : 'reopen',
        );
  }

  Future<void> _promptWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: issue.weight?.toString() ?? '',
    );
    final input = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue weight'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Empty clears the weight',
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (input == null || !context.mounted) {
      return;
    }
    // GitLab stores 0 / treats it as cleared weight.
    final weight = input.isEmpty ? 0 : int.tryParse(input);
    if (weight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a whole number')));
      return;
    }
    try {
      await ref
          .read(issuesRepositoryProvider)
          .updateIssue(loc.project, loc.iid, weight: weight);
      ref.invalidate(issueProvider(loc));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _promptDuration(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<void> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController();
    final duration = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 2h, 1d 4h, 30m'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (duration != null && duration.isNotEmpty) {
      await onSubmit(duration);
      ref.invalidate(issueProvider(loc));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(issuesRepositoryProvider);
    return PopupMenuButton<String>(
      onSelected: (action) async {
        switch (action) {
          case 'toggle':
            await _toggleState(ref);
            ref.invalidate(issueProvider(loc));
          case 'subscribe':
            await repo.setSubscribed(
              loc.project,
              loc.iid,
              subscribed: !issue.subscribed,
            );
            ref.invalidate(issueProvider(loc));
          case 'estimate':
            await _promptDuration(
              context,
              ref,
              title: 'Time estimate',
              onSubmit: (d) => repo.setTimeEstimate(loc.project, loc.iid, d),
            );
          case 'spent':
            await _promptDuration(
              context,
              ref,
              title: 'Add time spent',
              onSubmit: (d) => repo.addTimeSpent(loc.project, loc.iid, d),
            );
          case 'reset':
            await repo.resetTimeSpent(loc.project, loc.iid);
            ref.invalidate(issueProvider(loc));
          case 'weight':
            await _promptWeight(context, ref);
          case 'edit':
            unawaited(
              IssueFormScreen.show(
                context,
                projectId: loc.project,
                issue: issue,
              ),
            );
          case 'copy':
            if (issue.webUrl != null) {
              unawaited(Clipboard.setData(ClipboardData(text: issue.webUrl!)));
            }
          case 'open':
            if (issue.webUrl != null) {
              unawaited(launchExternal(issue.webUrl!));
            }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(issue.isOpen ? 'Close issue' : 'Reopen issue'),
        ),
        PopupMenuItem(
          value: 'subscribe',
          child: Text(issue.subscribed ? 'Unsubscribe' : 'Subscribe'),
        ),
        const PopupMenuItem(
          value: 'estimate',
          child: Text('Set time estimate'),
        ),
        const PopupMenuItem(value: 'spent', child: Text('Add time spent')),
        if ((issue.timeSpent ?? 0) > 0)
          const PopupMenuItem(value: 'reset', child: Text('Reset time spent')),
        const PopupMenuItem(value: 'weight', child: Text('Set weight')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'copy', child: Text('Copy link')),
        const PopupMenuItem(value: 'open', child: Text('Open in browser')),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StateChip.issueState(issue.state),
            if (issue.confidential) ...[
              const SizedBox(width: Insets.sm),
              StateChip(
                label: 'Confidential',
                tone: ChipTone.warning,
                icon: Icons.lock_outline,
              ),
            ],
          ],
        ),
        const SizedBox(height: Insets.sm),
        Text(issue.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.lg,
          runSpacing: Insets.xs,
          children: [
            if (issue.author != null)
              _AuthorLine(issue: issue, theme: theme, colors: colors),
            if (issue.milestone != null)
              _MetaRow(
                icon: Icons.flag_outlined,
                label: issue.milestone!.title,
                colors: colors,
                theme: theme,
              ),
            if (issue.dueDate != null)
              _MetaRow(
                icon: Icons.event_outlined,
                label: 'Due ${Format.date(issue.dueDate)}',
                colors: colors,
                theme: theme,
              ),
            if (issue.weight != null)
              _MetaRow(
                icon: Icons.scale_outlined,
                label: 'Weight ${issue.weight}',
                colors: colors,
                theme: theme,
              ),
            if ((issue.timeEstimate ?? 0) > 0 || (issue.timeSpent ?? 0) > 0)
              _MetaRow(
                icon: Icons.timer_outlined,
                label:
                    '${Format.humanDuration(issue.timeSpent)} spent'
                    ' of ${Format.humanDuration(issue.timeEstimate)}',
                colors: colors,
                theme: theme,
              ),
          ],
        ),
        if (issue.labels.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [for (final l in issue.labels) LabelChip(name: l)],
          ),
        ],
        if (issue.assignees.isNotEmpty) ...[
          const SizedBox(height: Insets.md),
          Row(
            children: [
              AvatarStack(users: issue.assignees),
              const SizedBox(width: Insets.sm),
              Text(
                issue.assignees.map((a) => a.name).join(', '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
        if (issue.closedBy != null || issue.taskStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.sm),
            child: Text(
              [
                if (issue.closedBy != null) 'Closed by ${issue.closedBy!.name}',
                if (issue.taskStatus != null) 'Tasks ${issue.taskStatus}',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.issue,
    required this.theme,
    required this.colors,
  });

  final Issue issue;
  final ThemeData theme;
  final GlamColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(
          name: issue.author!.name,
          avatarUrl: issue.author!.avatarUrl,
          radius: 10,
        ),
        const SizedBox(width: Insets.xs),
        Text(
          '${issue.author!.name} opened '
          '${Format.relative(issue.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final GlamColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.inkMuted),
        const SizedBox(width: Insets.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList({required this.loc});

  final IssueRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(issueNotesProvider(loc));
    return notes.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Insets.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(error: e),
      data: (state) {
        final visible = state.items.where((n) => !n.system).toList();
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Text(
              'No comments yet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return Column(
          children: [
            for (final note in visible)
              NoteCard(
                note: note,
                footer: ReactionsRow(
                  loc: (
                    kind: 'issue',
                    project: loc.project,
                    iid: loc.iid,
                    noteId: note.id,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
