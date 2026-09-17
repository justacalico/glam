import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/debouncer.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/groups/presentation/new_group_dialog.dart';

/// Top-level groups list with search.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer();
  String? _query;

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _newGroup() async {
    final group = await NewGroupDialog.show(context);
    if (group != null && mounted) {
      unawaited(context.push(Routes.group(group.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(groupsProvider(_query));
    final notifier = ref.read(groupsProvider(_query).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'New group',
            icon: const Icon(Icons.add),
            onPressed: () => unawaited(_newGroup()),
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
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => _debouncer(
                  () => setState(() => _query = v.isEmpty ? null : v),
                ),
                decoration: InputDecoration(
                  hintText: 'Search groups',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: Radii.borderMd,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
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
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                separator: Divider(
                  height: 1,
                  color: colors.border,
                  indent: Insets.lg,
                ),
                empty: const EmptyState(
                  icon: Icons.workspaces_outlined,
                  title: 'No groups found',
                ),
                itemBuilder: (context, index) =>
                    GroupTile(group: data.items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group row shared by the list and the subgroups tab.
class GroupTile extends StatelessWidget {
  const GroupTile({required this.group, super.key});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => unawaited(context.push(Routes.group(group.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            UserAvatar(
              name: group.name,
              avatarUrl: group.avatarUrl,
              radius: 18,
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: theme.textTheme.titleSmall),
                  Text(
                    group.fullPath,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (group.visibility == 'private')
              Icon(Icons.lock_outline, size: 15, color: colors.inkFaint),
            Icon(Icons.chevron_right, size: 18, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}
