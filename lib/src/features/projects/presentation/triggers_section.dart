import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_trigger.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Pipeline trigger tokens plus a CI lint runner. A new trigger's full
/// token is only shown once, straight from the create response.
class TriggersSection extends ConsumerWidget {
  const TriggersSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final triggers = ref.watch(pipelineTriggersProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Pipeline triggers')),
            TextButton.icon(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: triggers.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Text('$e'),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.bolt_outlined,
                      title: 'No triggers',
                    ),
                  )
                : Column(
                    children: [
                      for (final t in list)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.key_outlined, size: 18),
                          title: Text(
                            t.description.isEmpty
                                ? 'Trigger ${t.id}'
                                : t.description,
                          ),
                          subtitle: Text(
                            [
                              // Full token for own triggers, first-four
                              // prefix for everyone else's.
                              if (t.token != null)
                                t.token!.length > 4 ? t.token! : '${t.token}…',
                              if (t.lastUsedAt != null)
                                'last used ${Format.relative(t.lastUsedAt)}'
                              else
                                'never used',
                            ].join(' · '),
                            style: const TextStyle(
                              fontFamily: GlamFonts.mono,
                              fontSize: 11.5,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Delete trigger',
                            onPressed: () => _remove(context, ref, t),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.checklist_outlined, size: 20),
          title: const Text('Lint .gitlab-ci.yml'),
          subtitle: const Text('Validate CI config against this project'),
          onTap: () => _lint(context),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final desc = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New trigger'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'e.g. Deploy webhook',
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (desc == null || desc.isEmpty || !context.mounted) {
      return;
    }
    try {
      final trigger = await ref
          .read(pipelinesRepositoryProvider)
          .createTrigger(project.id, desc);
      if (!context.mounted) {
        return;
      }
      ref.invalidate(pipelineTriggersProvider(project.id));
      if (trigger.token != null) {
        await _showToken(context, trigger);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _showToken(BuildContext context, PipelineTrigger t) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trigger created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use this token to authenticate trigger requests.'),
            const SizedBox(height: Insets.sm),
            SelectableText(
              t.token!,
              style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: t.token!)));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Token copied')));
            },
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    PipelineTrigger t,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete trigger?',
      body: 'Requests using this token will stop working.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(pipelinesRepositoryProvider)
          .deleteTrigger(project.id, t.id);
      if (!context.mounted) {
        return;
      }
      ref.invalidate(pipelineTriggersProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _lint(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => _LintDialog(projectId: project.id),
    );
  }
}

class _LintDialog extends ConsumerStatefulWidget {
  const _LintDialog({required this.projectId});

  final int projectId;

  @override
  ConsumerState<_LintDialog> createState() => _LintDialogState();
}

class _LintDialogState extends ConsumerState<_LintDialog> {
  final _content = TextEditingController();
  CiLintResult? _result;
  var _busy = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final result = _result;

    return AlertDialog(
      title: const Text('Lint CI config'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _content,
                maxLines: 10,
                minLines: 6,
                style: const TextStyle(
                  fontFamily: GlamFonts.mono,
                  fontSize: 12.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Paste your .gitlab-ci.yml here',
                  border: OutlineInputBorder(),
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: Insets.md),
                Row(
                  children: [
                    Icon(
                      result.valid
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color: result.valid ? colors.merged : colors.danger,
                    ),
                    const SizedBox(width: Insets.sm),
                    Text(
                      result.valid ? 'Config is valid' : 'Config is invalid',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                for (final e in result.errors)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xs),
                    child: Text(
                      e,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  ),
                for (final w in result.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xs),
                    child: Text(
                      w,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
                if (result.jobs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.sm),
                    child: Text(
                      'Jobs: ${result.jobs.join(', ')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _busy ? null : _run,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lint'),
        ),
      ],
    );
  }

  Future<void> _run() async {
    final text = _content.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(pipelinesRepositoryProvider)
          .ciLint(widget.projectId, text);
      if (mounted) {
        setState(() => _result = result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAdminError(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
