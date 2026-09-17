import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';

/// Multi-select field backed by the project members list.
class MembersPickerField extends ConsumerWidget {
  const MembersPickerField({
    required this.projectId,
    required this.label,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Object projectId;
  final String label;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members =
        ref
            .watch(membersProvider((id: projectId, isProject: true)))
            .value
            ?.items ??
        const <Member>[];
    final names = members
        .where((m) => selected.contains(m.id))
        .map((m) => m.name)
        .join(', ');

    return InkWell(
      borderRadius: Radii.borderMd,
      onTap: () async {
        final next = await showDialog<Set<int>>(
          context: context,
          builder: (_) => MembersDialog(
            title: label,
            projectId: projectId,
            selected: selected,
          ),
        );
        if (next != null) {
          onChanged(next);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          names.isEmpty
              ? (selected.isEmpty ? 'None' : '${selected.length} selected')
              : names,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Searchable multi-select dialog over project members.
class MembersDialog extends ConsumerStatefulWidget {
  const MembersDialog({
    required this.title,
    required this.projectId,
    required this.selected,
    super.key,
  });

  final String title;
  final Object projectId;
  final Set<int> selected;

  @override
  ConsumerState<MembersDialog> createState() => _MembersDialogState();
}

class _MembersDialogState extends ConsumerState<MembersDialog> {
  late final Set<int> _selected = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(
      membersProvider((id: widget.projectId, isProject: true)),
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: wide,
              decoration: const InputDecoration(
                hintText: 'Search members',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: Insets.sm),
            Flexible(child: _memberList(membersAsync)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _memberList(AsyncValue<PagedListState<Member>> membersAsync) {
    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(
            membersProvider((id: widget.projectId, isProject: true)),
          ),
          child: const Text('Could not load members. Retry'),
        ),
      ),
      data: (state) {
        final visible = state.items
            .where(
              (m) =>
                  (m.state == null || m.state == 'active') &&
                  (_query.isEmpty ||
                      m.name.toLowerCase().contains(_query) ||
                      m.username.toLowerCase().contains(_query)),
            )
            .toList();
        if (visible.isEmpty) {
          return const Center(child: Text('No members found'));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
              unawaited(
                ref
                    .read(
                      membersProvider((
                        id: widget.projectId,
                        isProject: true,
                      )).notifier,
                    )
                    .loadMore(),
              );
            }
            return false;
          },
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in visible)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.name),
                  subtitle: Text('@${m.username}'),
                  value: _selected.contains(m.id),
                  onChanged: (v) => setState(() {
                    v! ? _selected.add(m.id) : _selected.remove(m.id);
                  }),
                ),
              if (state.loadingMore)
                const Padding(
                  padding: EdgeInsets.all(Insets.sm),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
