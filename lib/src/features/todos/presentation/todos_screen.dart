import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/filter_menu.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/todos/application/todos_providers.dart';
import 'package:glam/src/features/todos/domain/todo.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// The user's to-do queue: pending items with swipe-to-done.
class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  String? _state = 'pending';
  String? _type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = (state: _state, action: null, type: _type);
    final state = ref.watch(todosProvider(filter));
    final notifier = ref.read(todosProvider(filter).notifier);
    final states = {
      'pending': context.l10n.todoPending,
      'done': context.l10n.todoDone,
      null: context.l10n.stateAll,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.todosTitle),
        actions: [
          if (_state == 'pending')
            IconButton(
              tooltip: context.l10n.markAllDone,
              icon: const Icon(Icons.done_all, size: 20),
              onPressed: () => unawaited(_markAllDone(ref)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xs,
            ),
            child: Row(
              children: [
                for (final e in states.entries) ...[
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _state == e.key,
                    onSelected: (_) => setState(() => _state = e.key),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: Insets.sm),
                ],
                const Spacer(),
                FilterMenu(
                  title: context.l10n.type,
                  current: _type,
                  options: const ['Issue', 'MergeRequest', 'Commit', 'Epic'],
                  labels: {
                    'Issue': context.l10n.targetIssue,
                    'MergeRequest': context.l10n.targetMr,
                    'Commit': context.l10n.commit,
                    'Epic': context.l10n.targetEpic,
                  },
                  onSelect: (t) => setState(() => _type = t),
                ),
              ],
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
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                separator: Divider(
                  height: 1,
                  color: colors.border,
                  indent: Insets.lg,
                ),
                empty: EmptyState(
                  icon: Icons.check_circle_outline,
                  title: context.l10n.nothingOnYourPlate,
                ),
                itemBuilder: (context, index) {
                  final todo = data.items[index];
                  return _TodoTile(
                    todo: todo,
                    pending: _state == 'pending',
                    onDone: () => unawaited(notifier.markDone(todo)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllDone(WidgetRef ref) async {
    await ref.read(todosRepositoryProvider).markAllDone();
    ref.invalidate(todosProvider);
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
    required this.pending,
    required this.onDone,
  });

  final Todo todo;
  final bool pending;
  final VoidCallback onDone;

  IconData get _icon => switch (todo.targetType) {
    'Issue' => Icons.radio_button_unchecked,
    'MergeRequest' => Icons.merge_type_outlined,
    _ => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final route = todo.route;

    final tile = InkWell(
      onTap: route == null ? null : () => unawaited(context.push(route)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 18, color: colors.inkMuted),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.targetTitle,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      todo.author?.name ?? '',
                      todo.actionLabel,
                      if (todo.projectPath != null) todo.projectPath!,
                      Format.relative(todo.createdAt),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (pending)
              IconButton(
                tooltip: context.l10n.markDone,
                icon: Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: colors.inkMuted,
                ),
                onPressed: onDone,
              ),
          ],
        ),
      ),
    );

    if (!pending) {
      return tile;
    }
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDone(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Insets.xl),
        color: colors.success,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      child: tile,
    );
  }
}
