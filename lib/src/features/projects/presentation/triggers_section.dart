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
import 'package:glam/src/core/utils/l10n.dart';

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
            Expanded(child: SectionLabel(context.l10n.pipelineTriggers)),
            TextButton.icon(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.actionAdd),
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
                ? Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.bolt_outlined,
                      title: context.l10n.noTriggers,
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
                                ? context.l10n.triggerN(t.id)
                                : t.description,
                          ),
                          subtitle: Text(
                            [
                              // Full token for own triggers, first-four
                              // prefix for everyone else's.
                              if (t.token != null)
                                t.token!.length > 4 ? t.token! : '${t.token}…',
                              if (t.lastUsedAt != null)
                                context.l10n.lastUsedAt(
                                  Format.relative(t.lastUsedAt!),
                                )
                              else
                                context.l10n.neverUsed,
                            ].join(' · '),
                            style: const TextStyle(
                              fontFamily: GlamFonts.mono,
                              fontSize: 11.5,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, size: 18),
                            tooltip: context.l10n.deleteTrigger,
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
          leading: Icon(Icons.checklist_outlined, size: 20),
          title: Text(context.l10n.lintGitlabCiYml),
          subtitle: Text(context.l10n.validateCiConfigAgainstThisProject),
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
        title: Text(context.l10n.newTrigger),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.fieldDescription,
            hintText: context.l10n.eGDeployWebhook,
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.actionCreate),
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
        title: Text(context.l10n.triggerCreated),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.useThisTokenToAuthenticateTrigger),
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
              ).showSnackBar(SnackBar(content: Text(context.l10n.tokenCopied)));
            },
            icon: Icon(Icons.copy_outlined, size: 18),
            label: Text(context.l10n.actionCopy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionDone),
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
      title: context.l10n.deleteTriggerConfirm,
      body: context.l10n.triggerDeleteBody,
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
      title: Text(context.l10n.lintCiConfig),
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
                decoration: InputDecoration(
                  hintText: context.l10n.pasteYourGitlabCiYmlHere,
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
                      result.valid
                          ? context.l10n.configValid
                          : context.l10n.configInvalid,
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
                      context.l10n.lintJobsList(result.jobs.join(', ')),
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
          child: Text(context.l10n.actionClose),
        ),
        FilledButton(
          onPressed: _busy ? null : _run,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.lint),
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
