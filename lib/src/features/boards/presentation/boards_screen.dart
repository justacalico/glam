import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/avatar_stack.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/label_chip.dart';
import 'package:glam/src/features/boards/application/boards_providers.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

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
          return const EmptyState(
            icon: Icons.view_kanban_outlined,
            title: 'No boards',
          );
        }
        final board = items.firstWhere(
          (b) => b.id == _boardId,
          orElse: () => items.first,
        );
        return Column(
          children: [
            if (items.length > 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    Insets.sm,
                    Insets.lg,
                    Insets.xs,
                  ),
                  children: [
                    for (final b in items)
                      Padding(
                        padding: const EdgeInsets.only(right: Insets.sm),
                        child: ChoiceChip(
                          label: Text(b.name),
                          selected: board.id == b.id,
                          onSelected: (_) => setState(() => _boardId = b.id),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
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
          return const EmptyState(
            icon: Icons.view_column_outlined,
            title: 'This board has no lists',
          );
        }
        final sorted = [...lists]..sort((a, b) => a.position - b.position);
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(Insets.md),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
          itemBuilder: (context, index) => _Column(
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
