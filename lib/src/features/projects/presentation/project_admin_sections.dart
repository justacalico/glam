import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/webhook.dart';

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
            const Expanded(child: _SectionLabel('Webhooks')),
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
        _error(context, e.message);
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
        _error(context, e.message);
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
        _error(context, e.message);
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
  final _events = <String, bool>{
    'push_events': true,
    'tag_push_events': false,
    'issues_events': false,
    'note_events': false,
    'merge_requests_events': false,
    'pipeline_events': false,
    'job_events': false,
    'wiki_page_events': false,
    'deployment_events': false,
    'releases_events': false,
  };

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
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com/hook',
              ),
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

/// Deploy keys with add / remove.
class DeployKeysSection extends ConsumerWidget {
  const DeployKeysSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final keys = ref.watch(projectDeployKeysProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('Deploy keys')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _addKey(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: keys.when(
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
                      icon: Icons.vpn_key_outlined,
                      title: 'No deploy keys',
                    ),
                  )
                : Column(
                    children: [
                      for (final k in list)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.vpn_key_outlined, size: 18),
                          title: Text(k.title),
                          subtitle: Text(
                            [
                              k.fingerprint,
                              if (k.canPush) 'write access',
                              if (k.createdAt != null)
                                'added ${Format.date(k.createdAt!)}',
                            ].join(' · '),
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _deleteKey(context, ref, k),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _addKey(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final key = TextEditingController();
    var canPush = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add deploy key'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: Insets.sm),
                TextField(
                  controller: key,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Public key',
                    hintText: 'ssh-ed25519 AAAA…',
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Grant write access'),
                  value: canPush,
                  onChanged: (v) => setState(() => canPush = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) {
      title.dispose();
      key.dispose();
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .addDeployKey(
            project.id,
            title: title.text.trim(),
            key: key.text.trim(),
            canPush: canPush,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    } finally {
      title.dispose();
      key.dispose();
    }
  }

  Future<void> _deleteKey(
    BuildContext context,
    WidgetRef ref,
    DeployKey k,
  ) async {
    try {
      await ref
          .read(projectAdminActionsProvider)
          .deleteDeployKey(project.id, k.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}

/// Protected branch rules with protect / unprotect.
class ProtectedBranchesSection extends ConsumerWidget {
  const ProtectedBranchesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final branches = ref.watch(projectProtectedBranchesProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('Protected branches')),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Protect'),
              onPressed: () => _protect(context, ref),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: branches.when(
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
                      icon: Icons.shield_outlined,
                      title: 'No protected branches',
                    ),
                  )
                : Column(
                    children: [
                      for (final b in list)
                        _ProtectedBranchTile(
                          branch: b,
                          onDelete: () => _unprotect(context, ref, b),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _protect(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    var pushLevel = 40;
    var mergeLevel = 40;
    var forcePush = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Protect branch'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Branch or wildcard',
                    hintText: 'main or release-*',
                  ),
                ),
                const SizedBox(height: Insets.md),
                _LevelPicker(
                  label: 'Allowed to push',
                  value: pushLevel,
                  onChanged: (v) => setState(() => pushLevel = v),
                ),
                _LevelPicker(
                  label: 'Allowed to merge',
                  value: mergeLevel,
                  onChanged: (v) => setState(() => mergeLevel = v),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Allow force push'),
                  value: forcePush,
                  onChanged: (v) => setState(() => forcePush = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Protect'),
            ),
          ],
        ),
      ),
    );
    final branch = name.text.trim();
    name.dispose();
    if (ok != true || branch.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectAdminActionsProvider)
          .protectBranch(
            project.id,
            name: branch,
            pushLevel: pushLevel,
            mergeLevel: mergeLevel,
            allowForcePush: forcePush,
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }

  Future<void> _unprotect(
    BuildContext context,
    WidgetRef ref,
    ProtectedBranch b,
  ) async {
    try {
      await ref
          .read(projectAdminActionsProvider)
          .unprotectBranch(project.id, b.name);
    } on ApiException catch (e) {
      if (context.mounted) {
        _error(context, e.message);
      }
    }
  }
}

class _ProtectedBranchTile extends StatelessWidget {
  const _ProtectedBranchTile({required this.branch, required this.onDelete});

  final ProtectedBranch branch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final push = branch.pushLevels.map(ProtectedBranch.levelLabel).join(', ');
    final merge = branch.mergeLevels.map(ProtectedBranch.levelLabel).join(', ');
    return ListTile(
      dense: true,
      leading: Icon(
        branch.isWildcard ? Icons.star_outline : Icons.shield_outlined,
        size: 18,
      ),
      title: Text(
        branch.name,
        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5),
      ),
      subtitle: Text(
        [
          'push: $push',
          'merge: $merge',
          if (branch.allowForcePush) 'force push allowed',
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
          items: const [
            DropdownMenuItem(value: 0, child: Text('No one')),
            DropdownMenuItem(
              value: 30,
              child: Text('Developers + maintainers'),
            ),
            DropdownMenuItem(value: 40, child: Text('Maintainers')),
            DropdownMenuItem(value: 60, child: Text('Admins')),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

void _error(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
