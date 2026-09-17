import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/namespace.dart';
import 'package:glam/src/features/projects/domain/project.dart';

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
      title: const Text('New project'),
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
              namespaces.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) => DropdownButtonFormField<GitlabNamespace?>(
                  initialValue: _namespace,
                  decoration: const InputDecoration(
                    labelText: 'Namespace',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('Personal namespace')),
                    for (final n in items)
                      DropdownMenuItem(value: n, child: Text(n.label)),
                  ],
                  onChanged: (v) => setState(() => _namespace = v),
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
              CheckboxListTile(
                title: const Text('Initialize with a README'),
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
