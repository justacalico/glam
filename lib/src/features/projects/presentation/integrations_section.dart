import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/integration.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Project integrations (`/services`): enable/disable each service
/// and edit its property values. Secret fields may arrive masked;
/// unchanged fields are not sent back.
class IntegrationsSection extends ConsumerWidget {
  const IntegrationsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final integrations = ref.watch(projectIntegrationsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Integrations'),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: integrations.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text('$e'),
            ),
            data: (list) {
              final sorted = [...list]
                ..sort((a, b) {
                  if (a.active != b.active) return a.active ? -1 : 1;
                  return a.title.compareTo(b.title);
                });
              return sorted.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(Insets.lg),
                      child: EmptyState(
                        icon: Icons.extension_outlined,
                        title: 'No integrations',
                      ),
                    )
                  : Column(
                      children: [
                        for (final i in sorted)
                          _IntegrationTile(
                            integration: i,
                            onToggle: (v) =>
                                _toggle(context, ref, i, active: v),
                            onEdit: i.properties.isEmpty
                                ? null
                                : () => _edit(context, ref, i),
                          ),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Integration i, {
    required bool active,
  }) async {
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateIntegration(project.id, i.slug, active: active);
      ref.invalidate(projectIntegrationsProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Integration i) async {
    final changed = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _IntegrationDialog(integration: i),
    );
    if (changed == null || changed.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updateIntegration(project.id, i.slug, properties: changed);
      ref.invalidate(projectIntegrationsProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.integration,
    required this.onToggle,
    this.onEdit,
  });

  final Integration integration;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ListTile(
      title: Text(integration.title, style: theme.textTheme.bodyMedium),
      subtitle: integration.properties.isNotEmpty
          ? Text(
              integration.properties.keys.take(3).join(', ') +
                  (integration.properties.length > 3 ? ', …' : ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.inkFaint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: integration.active, onChanged: onToggle),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.tune, size: 18),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

/// Edits an integration's properties; pops with only the changed keys.
class _IntegrationDialog extends StatefulWidget {
  const _IntegrationDialog({required this.integration});

  final Integration integration;

  @override
  State<_IntegrationDialog> createState() => _IntegrationDialogState();
}

class _IntegrationDialogState extends State<_IntegrationDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final e in widget.integration.properties.entries)
      e.key: TextEditingController(text: e.value),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final changed = <String, String>{
      for (final e in _controllers.entries)
        if (e.value.text != widget.integration.properties[e.key])
          e.key: e.value.text,
    };
    Navigator.of(context).pop(changed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.integration.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in _controllers.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: e.key,
                      isDense: true,
                    ),
                  ),
                ),
              Text(
                'Secret values may appear masked. Fields you do not '
                'change are left as they are.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
