import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/webhook.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Editable fields from the webhook dialog.
typedef HookDraft = ({
  String url,
  String? token,
  Map<String, bool> events,
  bool sslVerify,
});

/// Shared webhook list for project and group scopes. Callers own
/// persistence; the section handles the add dialog, test and delete.
class WebhooksSection extends StatelessWidget {
  const WebhooksSection({
    required this.hooks,
    required this.onAdd,
    required this.onTest,
    required this.onDelete,
    this.isGroup = false,
    super.key,
  });

  final AsyncValue<List<Webhook>> hooks;
  final Future<void> Function(HookDraft draft) onAdd;
  final Future<void> Function(Webhook hook) onTest;
  final Future<void> Function(Webhook hook) onDelete;

  /// Group hooks expose the extra `subgroup_events` trigger.
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: Text(
                  context.l10n.webhooksTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.actionAdd),
              onPressed: () => _addHook(context),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: hooks.when(
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
                    padding: const EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.webhook_outlined,
                      title: context.l10n.webhooksEmpty,
                    ),
                  )
                : Column(
                    children: [
                      for (final h in list)
                        _HookTile(
                          hook: h,
                          onTest: () => _run(
                            context,
                            () => onTest(h),
                            success: context.l10n.webhookTestSent,
                          ),
                          onDelete: () => _confirmDelete(context, h),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String? success,
  }) async {
    try {
      await action();
      if (success != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _addHook(BuildContext context) async {
    final result = await showDialog<HookDraft>(
      context: context,
      builder: (_) => _HookDialog(isGroup: isGroup),
    );
    if (result == null || !context.mounted) {
      return;
    }
    await _run(context, () => onAdd(result));
  }

  Future<void> _confirmDelete(BuildContext context, Webhook hook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.webhookDeleteConfirm),
        content: Text(hook.url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    await _run(context, () => onDelete(hook));
  }
}

class _HookTile extends StatelessWidget {
  const _HookTile({
    required this.hook,
    required this.onTest,
    required this.onDelete,
  });

  final Webhook hook;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.webhook_outlined, size: 18),
      title: Text(
        hook.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: GlamFonts.mono, fontSize: 12),
      ),
      subtitle: Text(hook.eventLabels.join(', ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, size: 18),
            tooltip: context.l10n.webhookTestSend,
            onPressed: onTest,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _HookDialog extends StatefulWidget {
  const _HookDialog({required this.isGroup});

  final bool isGroup;

  @override
  State<_HookDialog> createState() => _HookDialogState();
}

class _HookDialogState extends State<_HookDialog> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  var _ssl = true;
  var _urlError = false;
  // Default webhook: push events on, everything else off.
  final _events = Map<String, bool>.of(
    const Webhook(id: 0, url: '').eventFlags,
  );

  Map<String, String> _labels(BuildContext context) => {
    'push_events': context.l10n.hookPushEvents,
    'tag_push_events': context.l10n.hookTagPush,
    'issues_events': context.l10n.hookIssues,
    'note_events': context.l10n.hookComments,
    'merge_requests_events': context.l10n.hookMergeRequests,
    'pipeline_events': context.l10n.hookPipeline,
    'job_events': context.l10n.hookJobs,
    'wiki_page_events': context.l10n.hookWiki,
    'deployment_events': context.l10n.hookDeployments,
    'releases_events': context.l10n.hookReleases,
    'subgroup_events': context.l10n.hookSubgroup,
  };

  @override
  void initState() {
    super.initState();
    if (widget.isGroup) {
      _events['subgroup_events'] = false;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.webhookAddTitle),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextField(
              controller: _url,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.webhookUrl,
                hintText: 'https://example.com/hook',
                errorText: _urlError ? context.l10n.errorRequired : null,
              ),
              onChanged: (_) {
                if (_urlError) {
                  setState(() => _urlError = false);
                }
              },
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _token,
              decoration: InputDecoration(
                labelText: context.l10n.webhookSecret,
              ),
            ),
            const SizedBox(height: Insets.md),
            for (final e in _events.entries)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_labels(context)[e.key]!),
                value: e.value,
                onChanged: (v) => setState(() => _events[e.key] = v ?? false),
              ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(context.l10n.webhookSsl),
              value: _ssl,
              onChanged: (v) => setState(() => _ssl = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final url = _url.text.trim();
            if (url.isEmpty) {
              setState(() => _urlError = true);
              return;
            }
            Navigator.pop(context, (
              url: url,
              token: _token.text.trim().isEmpty ? null : _token.text.trim(),
              events: Map.of(_events),
              sslVerify: _ssl,
            ));
          },
          child: Text(context.l10n.actionAdd),
        ),
      ],
    );
  }
}
