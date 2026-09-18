import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/app/router.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Draggable sheet listing users (followers, starrers, ...).
class UsersSheet extends ConsumerWidget {
  const UsersSheet({required this.title, required this.provider, super.key});

  final String title;
  final FutureProvider<List<GitLabUser>> provider;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required FutureProvider<List<GitLabUser>> provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => UsersSheet(title: title, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(provider);
    final colors = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: context.l10n.usersEmpty,
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final u = list[i];
                        return ListTile(
                          dense: true,
                          leading: UserAvatar(
                            name: u.name,
                            avatarUrl: u.avatarUrl,
                            radius: 16,
                          ),
                          title: Text(u.name),
                          subtitle: Text(
                            '@${u.username}',
                            style: TextStyle(color: colors.inkMuted),
                          ),
                          onTap: () => context.push(Routes.user(u.id)),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
