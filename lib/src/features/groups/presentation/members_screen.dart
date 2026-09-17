import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';

/// Access levels GitLab exposes through the members API.
const accessLevels = {
  10: 'Guest',
  15: 'Planner',
  20: 'Reporter',
  30: 'Developer',
  40: 'Maintainer',
  50: 'Owner',
};

/// Member list shared between project and group detail screens,
/// with invite / change-role / remove actions.
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

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xs,
            ),
            child: IconButton(
              tooltip: 'Invite member',
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => unawaited(
                MemberFormScreen.show(context, scope: scope).then((saved) {
                  if (saved) {
                    ref.invalidate(membersProvider);
                  }
                }),
              ),
            ),
          ),
        ),
        _AccessRequests(scope: scope),
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
                icon: Icons.people_outline,
                title: 'No members',
              ),
              itemBuilder: (context, index) =>
                  _MemberTile(member: data.items[index], scope: scope),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pending access requests with approve/deny actions. Hidden for
/// non-maintainers and when there are no requests.
class _AccessRequests extends ConsumerWidget {
  const _AccessRequests({required this.scope});

  final MemberScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(accessRequestsProvider(scope));
    final list = requests.value ?? const [];
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.lg,
        Insets.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              Insets.xs,
            ),
            child: Text(
              'Access requests',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          for (final m in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.xs,
                Insets.sm,
                Insets.xs,
              ),
              child: Row(
                children: [
                  UserAvatar(name: m.name, avatarUrl: m.avatarUrl, radius: 13),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      '${m.name} @${m.username}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _approve(context, ref, m.id),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () => _deny(context, ref, m.id),
                    child: Text('Deny', style: TextStyle(color: colors.danger)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, int userId) async {
    try {
      await ref
          .read(groupsRepositoryProvider)
          .approveAccessRequest(scope.id, userId, isProject: scope.isProject);
      ref
        ..invalidate(accessRequestsProvider(scope))
        ..invalidate(membersProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deny(BuildContext context, WidgetRef ref, int userId) async {
    try {
      await ref
          .read(groupsRepositoryProvider)
          .denyAccessRequest(scope.id, userId, isProject: scope.isProject);
      ref.invalidate(accessRequestsProvider(scope));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member, required this.scope});

  final Member member;
  final MemberScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm + 2,
        Insets.sm,
        Insets.sm + 2,
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
          PopupMenuButton<int>(
            iconSize: 18,
            icon: Icon(Icons.more_vert, size: 18, color: colors.inkFaint),
            itemBuilder: (context) => [
              for (final e in accessLevels.entries)
                PopupMenuItem(
                  value: e.key,
                  enabled: e.key != member.accessLevel,
                  child: Text('Make ${e.value}'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: -1,
                child: Text('Remove', style: TextStyle()),
              ),
            ],
            onSelected: (v) {
              if (v == -1) {
                unawaited(_remove(context, ref));
              } else {
                unawaited(_changeRole(ref, v));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(WidgetRef ref, int level) async {
    await ref
        .read(groupsRepositoryProvider)
        .updateMember(
          scope.id,
          member.id,
          isProject: scope.isProject,
          accessLevel: level,
        );
    ref.invalidate(membersProvider);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text(
          'They lose ${scope.isProject ? 'project' : 'group'} access.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(groupsRepositoryProvider)
        .removeMember(scope.id, member.id, isProject: scope.isProject);
    ref.invalidate(membersProvider);
  }
}

/// Invite form: username or id plus a role picker.
class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({required this.scope, super.key});

  final MemberScope scope;

  static Future<bool> show(
    BuildContext context, {
    required MemberScope scope,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final child = MemberFormScreen(scope: scope);
    final result = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(Insets.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => child,
          );
    return result ?? false;
  }

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _user = TextEditingController();
  int _level = 30;
  DateTime? _expires;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _user.text.trim();
    if (raw.isEmpty || _saving) {
      setState(
        () => _error = raw.isEmpty
            ? 'Username, user id, or email is required'
            : null,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final asId = int.tryParse(raw);
    try {
      await ref
          .read(groupsRepositoryProvider)
          .addMember(
            widget.scope.id,
            isProject: widget.scope.isProject,
            userId: asId,
            username: asId == null && !raw.contains('@') ? raw : null,
            email: asId == null && raw.contains('@') ? raw : null,
            accessLevel: _level,
            expiresAt: _expires?.toIso8601String().substring(0, 10),
          );
      if (mounted) {
        context.pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } on Object {
      setState(() {
        _saving = false;
        _error = 'Could not add the member';
      });
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _expires ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => _expires = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.lg,
        bottom: Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invite member', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _user,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Username, user id, or email',
              hintText: 'jane, 42, or jane@example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          DropdownButtonFormField<int>(
            initialValue: _level,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final e in accessLevels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _level = v ?? 30),
          ),
          const SizedBox(height: Insets.md),
          OutlinedButton.icon(
            onPressed: _pickExpiry,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
              _expires == null
                  ? 'No expiration'
                  : 'Expires ${_expires!.toIso8601String().substring(0, 10)}',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.sm),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
          const SizedBox(height: Insets.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => context.pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
