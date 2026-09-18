import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/environments/application/environments_providers.dart';
import 'package:glam/src/features/environments/domain/feature_flag.dart';
import 'package:glam/src/features/environments/domain/feature_flag_user_list.dart';
import 'package:glam/src/core/utils/l10n.dart';

enum _FlagsView { flags, userLists }

/// Feature flags tab on the project page: toggle or delete each flag,
/// and manage the user lists flag strategies can target.
class FeatureFlagsTab extends ConsumerStatefulWidget {
  const FeatureFlagsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  ConsumerState<FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends ConsumerState<FeatureFlagsTab> {
  var _view = _FlagsView.flags;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<_FlagsView>(
                  segments: [
                    ButtonSegment(
                      value: _FlagsView.flags,
                      label: Text(context.l10n.tabFlags),
                    ),
                    ButtonSegment(
                      value: _FlagsView.userLists,
                      label: Text(context.l10n.userLists),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => setState(() => _view = s.first),
                ),
              ),
              if (_view == _FlagsView.userLists)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.l10n.newList),
                  onPressed: () => _editUserList(context, null),
                ),
            ],
          ),
        ),
        Expanded(
          child: _view == _FlagsView.flags
              ? _FlagsList(projectId: widget.projectId)
              : _UserLists(
                  projectId: widget.projectId,
                  onEdit: (list) => _editUserList(context, list),
                ),
        ),
      ],
    );
  }

  Future<void> _editUserList(
    BuildContext context,
    FeatureFlagUserList? list,
  ) async {
    final saved = await _userListForm(context, existing: list);
    if (saved == null) return;
    try {
      final repo = ref.read(environmentsRepositoryProvider);
      if (list == null) {
        await repo.createFeatureFlagUserList(
          widget.projectId,
          name: saved.name,
          userXids: saved.xids,
        );
      } else {
        await repo.updateFeatureFlagUserList(
          widget.projectId,
          list.iid,
          name: saved.name,
          userXids: saved.xids,
        );
      }
      ref.invalidate(featureFlagUserListsProvider(widget.projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _FlagsList extends ConsumerWidget {
  const _FlagsList({required this.projectId});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider(projectId));
    final colors = context.colors;

    return AsyncValueWidget<List<FeatureFlag>>(
      value: flags,
      onRetry: () => ref.invalidate(featureFlagsProvider(projectId)),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              title: context.l10n.noFeatureFlags,
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(featureFlagsProvider(projectId)),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: colors.border),
                itemBuilder: (context, i) => _FlagTile(
                  flag: items[i],
                  onToggle: (v) => _toggle(context, ref, items[i], v),
                  onDelete: () => _confirmDelete(context, ref, items[i]),
                ),
              ),
            ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    FeatureFlag flag,
    bool active,
  ) async {
    try {
      await ref
          .read(environmentsRepositoryProvider)
          .updateFeatureFlag(projectId, flag.name, active: active);
      ref.invalidate(featureFlagsProvider(projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FeatureFlag flag,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteNamedConfirm(flag.name)),
        content: Text(context.l10n.theFlagIsRemovedFromEvery),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(environmentsRepositoryProvider)
          .deleteFeatureFlag(projectId, flag.name);
      ref.invalidate(featureFlagsProvider(projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.flag,
    required this.onToggle,
    required this.onDelete,
  });

  final FeatureFlag flag;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final scopes = flag.scopes.map((s) => s.environmentScope).join(', ');
    return ListTile(
      leading: Icon(
        flag.active ? Icons.flag : Icons.outlined_flag,
        size: 20,
        color: flag.active ? colors.success : colors.inkFaint,
      ),
      title: Text(flag.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        [
          if (flag.description.isNotEmpty) flag.description,
          if (scopes.isNotEmpty) scopes,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(color: colors.inkFaint),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: flag.active, onChanged: onToggle),
          IconButton(
            tooltip: context.l10n.actionDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _UserLists extends ConsumerWidget {
  const _UserLists({required this.projectId, required this.onEdit});

  final Object projectId;
  final ValueChanged<FeatureFlagUserList> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(featureFlagUserListsProvider(projectId));
    final colors = context.colors;

    return AsyncValueWidget<List<FeatureFlagUserList>>(
      value: lists,
      onRetry: () => ref.invalidate(featureFlagUserListsProvider(projectId)),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.group_outlined,
              title: context.l10n.noUserLists,
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(featureFlagUserListsProvider(projectId)),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: colors.border),
                itemBuilder: (context, i) => _UserListTile(
                  list: items[i],
                  onEdit: () => onEdit(items[i]),
                  onDelete: () => _confirmDelete(context, ref, items[i]),
                ),
              ),
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FeatureFlagUserList list,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteNamedConfirm(list.name)),
        content: Text(context.l10n.flagStrategiesUsingItStopMatching),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(environmentsRepositoryProvider)
          .deleteFeatureFlagUserList(projectId, list.iid);
      ref.invalidate(featureFlagUserListsProvider(projectId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({
    required this.list,
    required this.onEdit,
    required this.onDelete,
  });

  final FeatureFlagUserList list;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final count = list.userXids
        .split(',')
        .where((x) => x.trim().isNotEmpty)
        .length;
    return ListTile(
      leading: Icon(Icons.group_outlined, size: 20, color: colors.inkFaint),
      title: Text(list.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        context.l10n.userListSummary(
          count,
          count == 1 ? context.l10n.userSingular : context.l10n.userPlural,
          list.userXids,
        ),
        style: theme.textTheme.bodySmall?.copyWith(color: colors.inkFaint),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.actionDelete),
          ),
        ],
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      ),
    );
  }
}

/// Result of the user list form.
typedef _UserListDraft = ({String name, String xids});

/// Name plus comma-separated user IDs; used for both create and edit.
Future<_UserListDraft?> _userListForm(
  BuildContext context, {
  FeatureFlagUserList? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final xids = TextEditingController(text: existing?.userXids ?? '');
  var nameError = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          existing == null ? 'New user list' : 'Edit ${existing.name}',
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldName,
                  errorText: nameError ? 'Required' : null,
                ),
                onChanged: (_) {
                  if (nameError) {
                    setState(() => nameError = false);
                  }
                },
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: xids,
                decoration: InputDecoration(
                  labelText: context.l10n.userIds,
                  hintText: '123, 456',
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
            onPressed: () {
              if (name.text.trim().isEmpty) {
                setState(() => nameError = true);
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    ),
  );
  final draft = (name: name.text.trim(), xids: xids.text.replaceAll(' ', ''));
  name.dispose();
  xids.dispose();
  return ok == true ? draft : null;
}
