import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Group settings form (name, path, description, visibility). Returns
/// the updated [Group] or null when cancelled.
class EditGroupDialog extends ConsumerStatefulWidget {
  const EditGroupDialog({required this.group, super.key});

  static Future<Group?> show(BuildContext context, Group group) {
    return showDialog<Group>(
      context: context,
      builder: (_) => EditGroupDialog(group: group),
    );
  }

  final Group group;

  @override
  ConsumerState<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends ConsumerState<EditGroupDialog> {
  late final _name = TextEditingController(text: widget.group.name);
  late final _path = TextEditingController(text: widget.group.path);
  late final _description = TextEditingController(
    text: widget.group.description ?? '',
  );
  late String _visibility = widget.group.visibility ?? 'private';
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
    return AlertDialog(
      title: Text(context.l10n.editGroup),
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
                  border: OutlineInputBorder(),
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
          onPressed: _busy ? null : _save,
          child: Text(context.l10n.actionSave),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final group = await ref
          .read(groupsRepositoryProvider)
          .updateGroup(
            widget.group.id,
            name: name,
            path: _path.text.trim().isEmpty ? name : _path.text.trim(),
            description: _description.text.trim(),
            visibility: _visibility,
          );
      ref
        ..invalidate(groupProvider)
        ..invalidate(groupsProvider(null));
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
