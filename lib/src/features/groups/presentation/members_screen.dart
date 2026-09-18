import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/shared_group.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/search_field.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Access levels GitLab exposes through the members API.
const accessLevels = [10, 15, 20, 30, 40, 50];

/// Member list shared between project and group detail screens,
/// with invite / change-role / remove actions.
class MembersList extends ConsumerStatefulWidget {
  const MembersList({required this.id, required this.isProject, super.key});

  final Object id;
  final bool isProject;

  @override
  ConsumerState<MembersList> createState() => _MembersListState();
}

class _MembersListState extends ConsumerState<MembersList> {
  String? _query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scope = (id: widget.id, isProject: widget.isProject);
    final filter = (id: widget.id, isProject: widget.isProject, query: _query);
    final state = ref.watch(membersProvider(filter));
    final notifier = ref.read(membersProvider(filter).notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: SearchField(
            hint: context.l10n.pickerSearchMembers,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.xs,
              Insets.lg,
              Insets.xs,
            ),
            child: IconButton(
              tooltip: context.l10n.inviteMember,
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
        _PendingInvitations(scope: scope),
        _AccessRequests(scope: scope),
        if (!widget.isProject) _InvitedGroups(groupId: widget.id),
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
                icon: Icons.people_outline,
                title: context.l10n.noMembers,
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

/// Pending email invitations with a revoke action. Hidden for
/// non-maintainers and when there are none.
class _PendingInvitations extends ConsumerWidget {
  const _PendingInvitations({required this.scope});

  final MemberScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(invitationsProvider(scope));
    final list = pending.value ?? const [];
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final theme = Theme.of(context);
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
              context.l10n.pendingInvitations,
              style: theme.textTheme.labelMedium,
            ),
          ),
          for (final i in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.xs,
                Insets.sm,
                Insets.xs,
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 18, color: colors.inkMuted),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.name ?? i.inviteEmail,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          [
                            i.inviteEmail,
                            context.l10n.accessLevelName(i.accessLevel),
                            if (i.expiresAt != null)
                              context.l10n.expiresDate(
                                Format.date(i.expiresAt!),
                              ),
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _revoke(context, ref, i.inviteEmail),
                    child: Text(
                      context.l10n.actionRevoke,
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    try {
      await ref
          .read(groupsRepositoryProvider)
          .deleteInvitation(scope.id, email, isProject: scope.isProject);
      ref.invalidate(invitationsProvider(scope));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
              context.l10n.accessRequests,
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
                      context.l10n.memberDisplay(m.name, m.username),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _approve(context, ref, m.id),
                    child: Text(context.l10n.approve),
                  ),
                  TextButton(
                    onPressed: () => _deny(context, ref, m.id),
                    child: Text(
                      context.l10n.deny,
                      style: TextStyle(color: colors.danger),
                    ),
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

/// Groups this group is shared with; invite/remove. Only meaningful
/// on the group members tab, so callers gate it behind `!isProject`.
class _InvitedGroups extends ConsumerWidget {
  const _InvitedGroups({required this.groupId});

  final Object groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final shared = group?.sharedWithGroups ?? const [];
    final colors = context.colors;
    final theme = Theme.of(context);

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.invitedGroups,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.l10n.share),
                  onPressed: () => _share(context, ref, shared),
                ),
              ],
            ),
          ),
          if (shared.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                0,
                Insets.lg,
                Insets.md,
              ),
              child: Text(
                context.l10n.notSharedWithAnyGroup,
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            for (final g in shared)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.xs,
                  Insets.sm,
                  Insets.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: colors.inkMuted,
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text(
                        [
                          g.displayName,
                          g.roleLabel,
                          if (g.expiresAt != null)
                            'expires ${Format.date(g.expiresAt)}',
                        ].join(' · '),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      tooltip: context.l10n.unshare,
                      onPressed: () => _unshare(context, ref, g),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: Insets.xs),
        ],
      ),
    );
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    List<SharedGroup> shared,
  ) async {
    final groups = await ref.read(groupsProvider(null).future);
    final sharedIds = shared.map((g) => g.groupId).toSet();
    final candidates = groups.items
        .where((g) => !sharedIds.contains(g.id))
        .toList();
    if (!context.mounted) {
      return;
    }
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noGroupsLeftToShareWith)),
      );
      return;
    }
    var groupId = candidates.first.id;
    var accessLevel = 30;
    final days = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.shareWithGroup),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: groupId,
                  decoration: InputDecoration(labelText: context.l10n.group),
                  items: [
                    for (final g in candidates)
                      DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          g.fullPath.isEmpty ? g.name : g.fullPath,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => groupId = v ?? groupId),
                ),
                const SizedBox(height: Insets.sm),
                DropdownButtonFormField<int>(
                  initialValue: accessLevel,
                  decoration: InputDecoration(
                    labelText: context.l10n.maxAccessLevel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 10,
                      child: Text(context.l10n.roleGuest),
                    ),
                    DropdownMenuItem(
                      value: 15,
                      child: Text(context.l10n.planner),
                    ),
                    DropdownMenuItem(
                      value: 20,
                      child: Text(context.l10n.roleReporter),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(context.l10n.roleDeveloper),
                    ),
                    DropdownMenuItem(
                      value: 40,
                      child: Text(context.l10n.roleMaintainer),
                    ),
                  ],
                  onChanged: (v) => setState(() => accessLevel = v ?? 30),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldExpiresDays,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.share),
            ),
          ],
        ),
      ),
    );
    final expiryDays = int.tryParse(days.text.trim());
    days.dispose();
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupsRepositoryProvider)
          .shareGroup(
            this.groupId,
            groupId: groupId,
            accessLevel: accessLevel,
            expiresAt: expiryDays == null
                ? null
                : DateTime.now().add(Duration(days: expiryDays)),
          );
      ref.invalidate(groupProvider(this.groupId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _unshare(
    BuildContext context,
    WidgetRef ref,
    SharedGroup group,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeNamedConfirm(group.displayName)),
        content: Text(context.l10n.thatGroupLosesAccessToThis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionRemove),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupsRepositoryProvider)
          .unshareGroup(groupId, group.groupId);
      ref.invalidate(groupProvider(groupId));
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
              for (final e in accessLevels)
                PopupMenuItem(
                  value: e,
                  enabled: e != member.accessLevel,
                  child: Text(
                    context.l10n.makeP0(context.l10n.accessLevelName(e)),
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: -1,
                child: Text(context.l10n.actionRemove, style: TextStyle()),
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
        title: Text(context.l10n.removeNamedConfirm(member.name)),
        content: Text(
          context.l10n.theyLoseP0Access(
            scope.isProject ? context.l10n.projectWord : context.l10n.groupWord,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(context.l10n.actionRemove),
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
        () =>
            _error = raw.isEmpty ? context.l10n.memberIdentifierRequired : null,
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
        _error = context.l10n.memberAddFailed;
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
          Text(context.l10n.inviteMember, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _user,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.usernameUserIdOrEmail,
              hintText: context.l10n.jane42OrJaneExampleCom,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          DropdownButtonFormField<int>(
            initialValue: _level,
            decoration: InputDecoration(
              labelText: context.l10n.fieldRole,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final e in accessLevels)
                DropdownMenuItem(
                  value: e,
                  child: Text(context.l10n.accessLevelName(e)),
                ),
            ],
            onChanged: (v) => setState(() => _level = v ?? 30),
          ),
          const SizedBox(height: Insets.md),
          OutlinedButton.icon(
            onPressed: _pickExpiry,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
              _expires == null
                  ? context.l10n.noExpiration
                  : context.l10n.expiresOn(
                      _expires!.toIso8601String().substring(0, 10),
                    ),
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
                child: Text(context.l10n.actionCancel),
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
                    : Text(context.l10n.invite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
