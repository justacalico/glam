import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/namespace.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// New-project form. Returns the created [Project] or null when cancelled.
class NewProjectDialog extends ConsumerStatefulWidget {
  const NewProjectDialog({super.key});

  static Future<Project?> show(BuildContext context) {
    return showDialog<Project>(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
  }

  @override
  ConsumerState<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends ConsumerState<NewProjectDialog> {
  final _name = TextEditingController();
  final _path = TextEditingController();
  final _description = TextEditingController();
  GitlabNamespace? _namespace;
  String _visibility = 'private';
  bool _readme = false;
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
    final namespaces = ref.watch(namespacesProvider);

    return AlertDialog(
      title: Text(context.l10n.projectNew),
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
              SizedBox(height: Insets.md),
              TextField(
                controller: _path,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldPath,
                  hintText: context.l10n.fieldPathHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              namespaces.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) => DropdownButtonFormField<GitlabNamespace?>(
                  initialValue: _namespace,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldNamespace,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      child: Text(context.l10n.namespacePersonal),
                    ),
                    for (final n in items)
                      DropdownMenuItem(value: n, child: Text(n.label)),
                  ],
                  onChanged: (v) => setState(() => _namespace = v),
                ),
              ),
              SizedBox(height: Insets.md),
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
              SizedBox(height: Insets.md),
              TextField(
                controller: _description,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldDescription,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              CheckboxListTile(
                title: Text(context.l10n.initReadme),
                value: _readme,
                onChanged: (v) => setState(() => _readme = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
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
      final project = await ref
          .read(projectsRepositoryProvider)
          .createProject(
            name: name,
            path: _path.text.trim().isEmpty ? null : _path.text.trim(),
            namespaceId: _namespace?.id,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            visibility: _visibility,
            initializeWithReadme: _readme,
          );
      ref.invalidate(projectsListProvider);
      if (mounted) {
        Navigator.pop(context, project);
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
