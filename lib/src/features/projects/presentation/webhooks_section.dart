import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/webhook.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// Webhooks list with add / test / delete.
class WebhooksSection extends ConsumerWidget {
  const WebhooksSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hooks = ref.watch(projectHooksProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Webhooks')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _addHook(context, ref),
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
                ? const Padding(
                    padding: EdgeInsets.all(Insets.lg),
                    child: EmptyState(
                      icon: Icons.webhook_outlined,
                      title: 'No webhooks',
                    ),
                  )
                : Column(
                    children: [
                      for (final h in list)
                        _HookTile(
                          hook: h,
                          onTest: () => _testHook(context, ref, h),
                          onDelete: () => _deleteHook(context, ref, h),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _addHook(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_HookDraft>(
      context: context,
      builder: (_) => const _HookDialog(),
    );
    if (result == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .addHook(
            project.id,
            url: result.url,
            token: result.token,
            events: result.events,
            sslVerify: result.sslVerify,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _testHook(
    BuildContext context,
    WidgetRef ref,
    Webhook hook,
  ) async {
    try {
      await ref.read(projectAdminActionsProvider).testHook(project.id, hook.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Test event sent')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _deleteHook(
    BuildContext context,
    WidgetRef ref,
    Webhook hook,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete webhook?'),
        content: Text(hook.url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteHook(project.id, hook.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
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
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
      ),
      subtitle: Text(hook.eventLabels.join(', ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, size: 18),
            tooltip: 'Send test event',
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

class _HookDraft {
  const _HookDraft({
    required this.url,
    this.token,
    required this.events,
    required this.sslVerify,
  });

  final String url;
  final String? token;
  final Map<String, bool> events;
  final bool sslVerify;
}

class _HookDialog extends StatefulWidget {
  const _HookDialog();

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

  static const _labels = {
    'push_events': 'Push events',
    'tag_push_events': 'Tag push events',
    'issues_events': 'Issues',
    'note_events': 'Comments',
    'merge_requests_events': 'Merge requests',
    'pipeline_events': 'Pipeline',
    'job_events': 'Jobs',
    'wiki_page_events': 'Wiki pages',
    'deployment_events': 'Deployments',
    'releases_events': 'Releases',
  };

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add webhook'),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextField(
              controller: _url,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com/hook',
                errorText: _urlError ? 'Required' : null,
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
              decoration: const InputDecoration(
                labelText: 'Secret token (optional)',
              ),
            ),
            const SizedBox(height: Insets.md),
            for (final e in _events.entries)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_labels[e.key]!),
                value: e.value,
                onChanged: (v) => setState(() => _events[e.key] = v ?? false),
              ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('SSL verification'),
              value: _ssl,
              onChanged: (v) => setState(() => _ssl = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final url = _url.text.trim();
            if (url.isEmpty) {
              setState(() => _urlError = true);
              return;
            }
            Navigator.pop(
              context,
              _HookDraft(
                url: url,
                token: _token.text.trim().isEmpty ? null : _token.text.trim(),
                events: Map.of(_events),
                sslVerify: _ssl,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
