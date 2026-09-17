import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';

/// New-group form. Returns the created [Group] or null when cancelled.
class NewGroupDialog extends ConsumerStatefulWidget {
  const NewGroupDialog({super.key});

  static Future<Group?> show(BuildContext context) {
    return showDialog<Group>(
      context: context,
      builder: (_) => const NewGroupDialog(),
    );
  }

  @override
  ConsumerState<NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends ConsumerState<NewGroupDialog> {
  final _name = TextEditingController();
  final _path = TextEditingController();
  final _description = TextEditingController();
  Group? _parent;
  String _visibility = 'private';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(ownedGroupsProvider);

    return AlertDialog(
      title: const Text('New group'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _path,
                decoration: const InputDecoration(
                  labelText: 'Path',
                  hintText: 'Defaults to the name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              owned.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) => DropdownButtonFormField<Group?>(
                  initialValue: _parent,
                  decoration: const InputDecoration(
                    labelText: 'Parent group',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('Top level')),
                    for (final g in items)
                      DropdownMenuItem(value: g, child: Text(g.fullPath)),
                  ],
                  onChanged: (v) => setState(() => _parent = v),
                ),
              ),
              const SizedBox(height: Insets.md),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _visibility = v);
                  }
                },
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final group = await ref
          .read(groupsRepositoryProvider)
          .createGroup(
            name: name,
            path: _path.text.trim().isEmpty ? name : _path.text.trim(),
            parentId: _parent?.id,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            visibility: _visibility,
          );
      ref.invalidate(groupsProvider(null));
      if (mounted) {
        Navigator.pop(context, group);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
