import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/home/presentation/app_shell.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Bottom sheet holding the secondary destinations on mobile.
Future<void> showMoreSheet(
  BuildContext context,
  StatefulNavigationShell shell,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _MoreSheet(shell: shell),
  );
}

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final session = ref.watch(sessionProvider).value;
    final secondary = navDestinations
        .where((d) => d.branch >= primaryNavCount)
        .toList();

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: Insets.lg),
        children: [
          if (session != null)
            ListTile(
              leading: UserAvatar(
                name: session.user.name,
                avatarUrl: session.user.avatarUrl,
              ),
              title: Text(session.user.name),
              subtitle: Text('@${session.user.username}'),
              trailing: Icon(Icons.chevron_right, color: colors.inkFaint),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(context.push(Routes.profile));
              },
            ),
          if (session != null) const Divider(height: Insets.xl),
          for (final d in secondary)
            ListTile(
              leading: Icon(d.icon),
              title: Text(context.l10n.navLabel(d.path)),
              onTap: () {
                Navigator.of(context).pop();
                shell.goBranch(d.branch);
              },
            ),
        ],
      ),
    );
  }
}
