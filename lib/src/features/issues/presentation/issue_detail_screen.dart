import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/comment_composer.dart';
import 'package:glam/src/core/widgets/duration_dialog.dart';
import 'package:glam/src/core/widgets/error_view.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/core/widgets/markdown_viewer.dart';
import 'package:glam/src/core/widgets/note_card.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/core/widgets/state_events_row.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/engagement/application/engagement_providers.dart';
import 'package:glam/src/features/engagement/presentation/reactions_row.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/presentation/issue_form_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_links_section.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
        title: Text(context.l10n.issueIid(iid)),
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
                  _Header(issue: issue, loc: _loc),
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
                    context.l10n.activityTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.sm),
                  StateEventsRow(
                    events: ref.watch(issueStateEventsProvider(_loc)),
                    milestoneEvents: ref.watch(
                      issueMilestoneEventsProvider(_loc),
                    ),
                    labelEvents: ref.watch(issueLabelEventsProvider(_loc)),
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
              onUpload: (bytes, name) => ref
                  .read(projectsRepositoryProvider)
                  .uploadFile(_loc.project, bytes, name),
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

  Future<void> _promptMove(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var error = false;
    final target = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.moveIssue),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.destinationProject,
              hintText: context.l10n.groupProject,
              errorText: error ? context.l10n.enterProjectPath : null,
            ),
            onChanged: (_) {
              if (error) {
                setState(() => error = false);
              }
            },
            onSubmitted: (v) {
              if (v.trim().isEmpty) {
                setState(() => error = true);
                return;
              }
              Navigator.pop(context, v.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) {
                  setState(() => error = true);
                  return;
                }
                Navigator.pop(context, v);
              },
              child: Text(context.l10n.move),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (target == null || !context.mounted) {
      return;
    }
    try {
      final dest = await ref.read(projectsRepositoryProvider).get(target);
      if (!context.mounted) {
        return;
      }
      final moved = await ref
          .read(issuesRepositoryProvider)
          .moveIssue(loc.project, loc.iid, dest.id);
      ref
        ..invalidate(issueProvider(loc))
        ..invalidate(issuesProvider)
        ..invalidate(projectIssuesProvider);
      if (context.mounted) {
        // The issue now lives under the destination project.
        context.pushReplacement(
          Routes.projectIssue(moved.projectId, moved.iid),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _promptWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: issue.weight?.toString() ?? '',
    );
    final input = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.issueWeight),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: context.l10n.emptyClearsTheWeight,
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.actionSave),
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.enterAWholeNumber)));
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
    final duration = await promptDuration(context, title: title);
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
              title: context.l10n.timeEstimate,
              onSubmit: (d) => repo.setTimeEstimate(loc.project, loc.iid, d),
            );
          case 'spent':
            await _promptDuration(
              context,
              ref,
              title: context.l10n.addTimeSpent,
              onSubmit: (d) => repo.addTimeSpent(loc.project, loc.iid, d),
            );
          case 'reset':
            await repo.resetTimeSpent(loc.project, loc.iid);
            ref.invalidate(issueProvider(loc));
          case 'weight':
            await _promptWeight(context, ref);
          case 'clone':
            final copy = await repo.cloneIssue(
              loc.project,
              loc.iid,
              toProjectId: issue.projectId,
            );
            ref
              ..invalidate(issuesProvider)
              ..invalidate(projectIssuesProvider);
            if (context.mounted) {
              context.pushReplacement(
                Routes.projectIssue(copy.projectId, copy.iid),
              );
            }
            return;
          case 'move':
            await _promptMove(context, ref);
            return;
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
          child: Text(
            issue.isOpen ? context.l10n.closeIssue : context.l10n.reopenIssue,
          ),
        ),
        PopupMenuItem(
          value: 'subscribe',
          child: Text(
            issue.subscribed
                ? context.l10n.unsubscribe
                : context.l10n.subscribe,
          ),
        ),
        PopupMenuItem(
          value: 'estimate',
          child: Text(context.l10n.setTimeEstimate),
        ),
        PopupMenuItem(value: 'spent', child: Text(context.l10n.addTimeSpent)),
        if ((issue.timeSpent ?? 0) > 0)
          PopupMenuItem(
            value: 'reset',
            child: Text(context.l10n.resetTimeSpent),
          ),
        PopupMenuItem(value: 'weight', child: Text(context.l10n.setWeight)),
        PopupMenuItem(value: 'clone', child: Text(context.l10n.cloneIssue)),
        if (issue.isOpen)
          PopupMenuItem(value: 'move', child: Text(context.l10n.moveIssue)),
        PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
        PopupMenuItem(value: 'copy', child: Text(context.l10n.copyLink)),
        PopupMenuItem(
          value: 'open',
          child: Text(context.l10n.actionOpenBrowser),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.issue, required this.loc});

  final Issue issue;
  final IssueRef loc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StateChip.issueState(context.l10n, issue.state),
            if (issue.confidential) ...[
              const SizedBox(width: Insets.sm),
              StateChip(
                label: context.l10n.confidential,
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
                label: context.l10n.issueDueDate(Format.date(issue.dueDate)),
                colors: colors,
                theme: theme,
              ),
            if (issue.weight != null)
              _MetaRow(
                icon: Icons.scale_outlined,
                label: context.l10n.issueWeightValue('${issue.weight}'),
                colors: colors,
                theme: theme,
              ),
            if (issue.iteration != null)
              _MetaRow(
                icon: Icons.event_repeat_outlined,
                label: issue.iteration!.localizedLabel(context.l10n),
                colors: colors,
                theme: theme,
              ),
            if ((issue.timeEstimate ?? 0) > 0 || (issue.timeSpent ?? 0) > 0)
              _MetaRow(
                icon: Icons.timer_outlined,
                label: context.l10n.timeSpentOf(
                  Format.humanDuration(issue.timeSpent),
                  Format.humanDuration(issue.timeEstimate),
                ),
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
                if (issue.closedBy != null)
                  context.l10n.closedByName(issue.closedBy!.name),
                if (issue.taskStatus != null)
                  context.l10n.tasksStatus(issue.taskStatus!),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ),
        _ParticipantsLine(loc: loc),
      ],
    );
  }
}

class _ParticipantsLine extends ConsumerWidget {
  const _ParticipantsLine({required this.loc});

  final IssueRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(issueParticipantsProvider(loc));
    return participants.maybeWhen(
      data: (users) => users.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Row(
                children: [
                  AvatarStack(users: users, max: 8),
                  const SizedBox(width: Insets.sm),
                  Text(
                    '${users.length} '
                    'participant${users.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
      orElse: () => const SizedBox.shrink(),
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
        Flexible(
          child: Text(
            context.l10n.openedByAt(
              issue.author!.name,
              Format.relative(issue.createdAt),
            ),
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    final myId = ref.watch(sessionProvider).value?.user.id;
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
              context.l10n.noCommentsYet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return Column(
          children: [
            for (final note in visible)
              NoteCard(
                note: note,
                onEdit: note.author?.id == myId
                    ? (body) => ref
                          .read(issueNotesProvider(loc).notifier)
                          .editComment(note.id, body)
                    : null,
                onDelete: note.author?.id == myId
                    ? () => ref
                          .read(issueNotesProvider(loc).notifier)
                          .deleteComment(note.id)
                    : null,
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
