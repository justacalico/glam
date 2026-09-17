import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/features/boards/application/boards_providers.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';

/// Boards tab inside project detail: a board picker plus a horizontal
/// Kanban view.
class ProjectBoardsTab extends ConsumerStatefulWidget {
  const ProjectBoardsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<ProjectBoardsTab> createState() => _ProjectBoardsTabState();
}

class _ProjectBoardsTabState extends ConsumerState<ProjectBoardsTab> {
  int? _boardId;

  @override
  Widget build(BuildContext context) {
    final boards = ref.watch(boardsProvider(widget.projectId));

    return AsyncValueWidget(
      value: boards,
      onRetry: () => ref.invalidate(boardsProvider(widget.projectId)),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.view_kanban_outlined,
            title: 'No boards',
            actionLabel: 'New board',
            onAction: () => unawaited(_editBoard(null)),
          );
        }
        final board = items.firstWhere(
          (b) => b.id == _boardId,
          orElse: () => items.first,
        );
        return Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(
                        Insets.lg,
                        Insets.sm,
                        Insets.xs,
                        Insets.xs,
                      ),
                      children: [
                        for (final b in items)
                          Padding(
                            padding: const EdgeInsets.only(right: Insets.sm),
                            child: ChoiceChip(
                              label: Text(b.name),
                              selected: board.id == b.id,
                              onSelected: (_) =>
                                  setState(() => _boardId = b.id),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'New board',
                    iconSize: 18,
                    icon: const Icon(Icons.add),
                    onPressed: () => unawaited(_editBoard(null)),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Board actions',
                    iconSize: 18,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'rename') {
                        unawaited(_editBoard(board));
                      } else if (v == 'delete') {
                        unawaited(_deleteBoard(board));
                      }
                    },
                  ),
                  const SizedBox(width: Insets.sm),
                ],
              ),
            ),
            Expanded(
              child: _Kanban(
                loc: (projectId: widget.projectId, boardId: board.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editBoard(Board? existing) async {
    final draft = await showDialog<_BoardDraft>(
      context: context,
      builder: (_) =>
          _BoardDialog(projectId: widget.projectId, existing: existing),
    );
    if (draft == null || !mounted) {
      return;
    }
    try {
      final repo = ref.read(boardsRepositoryProvider);
      final board = existing == null
          ? await repo.createBoard(
              widget.projectId,
              name: draft.name,
              milestoneId: draft.milestoneId,
              labels: draft.labels,
              weight: draft.weight,
            )
          : await repo.updateBoard(
              widget.projectId,
              existing.id,
              name: draft.name,
              milestoneId: draft.milestoneId,
              labels: draft.labels,
              weight: draft.weight,
            );
      setState(() => _boardId = board.id);
      ref.invalidate(boardsProvider(widget.projectId));
    } on ApiException catch (e) {
      if (mounted) {
        _error(e.message);
      }
    }
  }

  Future<void> _deleteBoard(Board board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${board.name}?'),
        content: const Text('Issues stay on the project; only the board goes.'),
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
          .read(boardsRepositoryProvider)
          .deleteBoard(widget.projectId, board.id);
      setState(() => _boardId = null);
      ref.invalidate(boardsProvider(widget.projectId));
    } on ApiException catch (e) {
      if (mounted) {
        _error(e.message);
      }
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Kanban extends ConsumerWidget {
  const _Kanban({required this.loc});

  final BoardRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(boardListsProvider(loc));
    final colors = context.colors;

    return AsyncValueWidget(
      value: lists,
      onRetry: () => ref.invalidate(boardListsProvider(loc)),
      data: (lists) {
        if (lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyState(
                  icon: Icons.view_column_outlined,
                  title: 'This board has no lists',
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add list'),
                  onPressed: () =>
                      unawaited(_AddListTile.pick(context, ref, loc)),
                ),
              ],
            ),
          );
        }
        final sorted = [...lists]..sort((a, b) => a.position - b.position);
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(Insets.md),
          itemCount: sorted.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
          itemBuilder: (context, index) => index == sorted.length
              ? _AddListTile(loc: loc)
              : _Column(
                  list: sorted[index],
                  loc: (
                    projectId: loc.projectId,
                    boardId: loc.boardId,
                    listId: sorted[index].id,
                  ),
                  allLists: sorted,
                  colors: colors,
                ),
        );
      },
    );
  }
}

/// Dashed trailing tile that opens a label picker and adds a label list.
class _AddListTile extends ConsumerWidget {
  const _AddListTile({required this.loc});

  final BoardRef loc;

  static Future<void> pick(
    BuildContext context,
    WidgetRef ref,
    BoardRef loc,
  ) async {
    final label = await showDialog<Label>(
      context: context,
      builder: (context) => _LabelPicker(projectId: loc.projectId),
    );
    if (label == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(boardsRepositoryProvider)
          .createList(loc.projectId, loc.boardId, labelId: label.id);
      ref.invalidate(boardListsProvider(loc));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add list'),
          onPressed: () => unawaited(pick(context, ref, loc)),
        ),
      ),
    );
  }
}

class _LabelPicker extends ConsumerWidget {
  const _LabelPicker({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(labelsProvider((id: projectId, isProject: true)));
    return AlertDialog(
      title: const Text('Add list'),
      content: SizedBox(
        width: 320,
        child: labels.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Insets.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Text('$e'),
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: Text('No labels on this project.'),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final l in items)
                        ListTile(
                          dense: true,
                          title: LabelChip(name: l.name),
                          onTap: () => Navigator.pop(context, l),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({
    required this.list,
    required this.loc,
    required this.allLists,
    required this.colors,
  });

  final BoardList list;
  final BoardListRef loc;
  final List<BoardList> allLists;
  final GlamColors colors;

  Future<void> _moveIssue(
    BuildContext context,
    WidgetRef ref,
    Issue issue,
    BoardList target,
  ) async {
    await ref
        .read(boardsRepositoryProvider)
        .moveIssue(
          loc.projectId,
          loc.boardId,
          loc.listId,
          issue.id,
          toListId: target.id,
        );
    ref
      ..invalidate(boardIssuesProvider(loc))
      ..invalidate(
        boardIssuesProvider((
          projectId: loc.projectId,
          boardId: loc.boardId,
          listId: target.id,
        )),
      );
  }

  Future<void> _removeList(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${list.title}?'),
        content: const Text('Issues keep their label; only the column goes.'),
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
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(boardsRepositoryProvider)
          .deleteList(loc.projectId, loc.boardId, loc.listId);
      ref.invalidate(
        boardListsProvider((projectId: loc.projectId, boardId: loc.boardId)),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(boardIssuesProvider(loc));
    final theme = Theme.of(context);

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.md,
              Insets.sm,
              Insets.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    list.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (list.issuesCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.sm,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: Radii.borderPill,
                    ),
                    child: Text(
                      '${list.issuesCount}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                if (list.listType == 'label')
                  PopupMenuButton<String>(
                    tooltip: 'List actions',
                    iconSize: 16,
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: colors.inkFaint,
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove list'),
                      ),
                    ],
                    onSelected: (_) => unawaited(_removeList(context, ref)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: issues,
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        'No issues',
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        Insets.sm,
                        0,
                        Insets.sm,
                        Insets.sm,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _Card(
                        issue: items[index],
                        onMove: (target) => unawaited(
                          _moveIssue(context, ref, items[index], target),
                        ),
                        targets: allLists.where((l) => l.id != list.id),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.issue,
    required this.onMove,
    required this.targets,
  });

  final Issue issue;
  final ValueChanged<BoardList> onMove;
  final Iterable<BoardList> targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.borderSm,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: Radii.borderSm,
        onTap: () => unawaited(
          context.push(Routes.projectIssue(issue.projectId, issue.iid)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      issue.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<BoardList>(
                    tooltip: 'Move to',
                    iconSize: 16,
                    icon: Icon(
                      Icons.swap_horiz,
                      size: 16,
                      color: colors.inkFaint,
                    ),
                    itemBuilder: (context) => [
                      for (final l in targets)
                        PopupMenuItem(value: l, child: Text(l.title)),
                    ],
                    onSelected: onMove,
                  ),
                ],
              ),
              if (issue.labels.isNotEmpty) ...[
                const SizedBox(height: Insets.sm),
                Wrap(
                  spacing: Insets.xs,
                  runSpacing: Insets.xs,
                  children: [
                    for (final l in issue.labels.take(3)) LabelChip(name: l),
                  ],
                ),
              ],
              const SizedBox(height: Insets.sm),
              Row(
                children: [
                  Text('#${issue.iid}', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  if (issue.assignees.isNotEmpty)
                    AvatarStack(users: issue.assignees, radius: 8),
                  if (issue.dueDate != null) ...[
                    const SizedBox(width: Insets.sm),
                    Text(
                      Format.date(issue.dueDate),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the board dialog returns on save.
typedef _BoardDraft = ({
  String name,
  int? milestoneId,
  List<String> labels,
  int? weight,
});

/// Board create/edit dialog: name plus the scope filters GitLab
/// accepts (milestone, labels, weight).
class _BoardDialog extends ConsumerStatefulWidget {
  const _BoardDialog({required this.projectId, this.existing});

  final Object projectId;
  final Board? existing;

  @override
  ConsumerState<_BoardDialog> createState() => _BoardDialogState();
}

class _BoardDialogState extends ConsumerState<_BoardDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _labels = TextEditingController(
    text: widget.existing?.labels.join(', ') ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.existing?.weight?.toString() ?? '',
  );
  int? _milestone;

  @override
  void initState() {
    super.initState();
    _milestone = widget.existing?.milestoneId;
  }

  @override
  void dispose() {
    _name.dispose();
    _labels.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final milestones = ref.watch(
      milestonesProvider((
        scope: (id: widget.projectId, isProject: true),
        state: 'active',
      )),
    );

    return AlertDialog(
      title: Text(existing == null ? 'New board' : 'Edit board'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: Insets.md),
              milestones.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (state) => DropdownButtonFormField<int?>(
                  initialValue: _milestone,
                  decoration: const InputDecoration(
                    labelText: 'Milestone scope',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('No milestone')),
                    for (final m in state.items)
                      DropdownMenuItem(value: m.id, child: Text(m.title)),
                  ],
                  onChanged: (v) => setState(() => _milestone = v),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _labels,
                decoration: const InputDecoration(
                  labelText: 'Label scope',
                  hintText: 'bug, frontend',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight scope',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    final labels = _labels.text
        .split(',')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    // Clearing a set milestone means sending -1, not omitting the key.
    final milestoneId = _milestone == null && widget.existing != null
        ? -1
        : _milestone;
    Navigator.pop(context, (
      name: name,
      milestoneId: milestoneId,
      labels: labels,
      weight: int.tryParse(_weight.text.trim()),
    ));
  }
}
