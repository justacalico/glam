import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/core/utils/l10n.dart';

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
      title: Text(context.l10n.newGroup),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _path,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldPath,
                  hintText: context.l10n.fieldPathHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              owned.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) => DropdownButtonFormField<Group?>(
                  initialValue: _parent,
                  decoration: InputDecoration(
                    labelText: context.l10n.parentGroup,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(child: Text(context.l10n.topLevel)),
                    for (final g in items)
                      DropdownMenuItem(value: g, child: Text(g.fullPath)),
                  ],
                  onChanged: (v) => setState(() => _parent = v),
                ),
              ),
              const SizedBox(height: Insets.md),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldVisibility,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'private',
                    child: Text(context.l10n.visibilityPrivate),
                  ),
                  DropdownMenuItem(
                    value: 'internal',
                    child: Text(context.l10n.visibilityInternal),
                  ),
                  DropdownMenuItem(
                    value: 'public',
                    child: Text(context.l10n.visibilityPublic),
                  ),
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
                decoration: InputDecoration(
                  labelText: context.l10n.fieldDescription,
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
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(context.l10n.actionCreate),
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
