import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';

/// Member list shared between project and group detail screens.
class MembersList extends ConsumerWidget {
  const MembersList({required this.id, required this.isProject, super.key});

  final Object id;
  final bool isProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final scope = (id: id, isProject: isProject);
    final state = ref.watch(membersProvider(scope));
    final notifier = ref.read(membersProvider(scope).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border, indent: Insets.lg),
        empty: const EmptyState(
          icon: Icons.people_outline,
          title: 'No members',
        ),
        itemBuilder: (context, index) => _MemberTile(member: data.items[index]),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.sm + 2,
      ),
      child: Row(
        children: [
          UserAvatar(
            name: member.name,
            avatarUrl: member.avatarUrl,
            radius: 16,
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: theme.textTheme.titleSmall),
                Text(
                  member.expiresAt != null
                      ? '@${member.username} · until '
                          '${Format.date(member.expiresAt)}'
                      : '@${member.username}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: Radii.borderPill,
              border: Border.all(color: colors.border),
            ),
            child: Text(member.roleLabel, style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}
