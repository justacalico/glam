import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_pages.dart';
import 'package:glam/src/features/projects/presentation/admin_helpers.dart';

/// GitLab Pages: site URL, HTTPS-only and unique-domain switches,
/// custom domains, and unpublish. Hidden where Pages is off.
class PagesSection extends ConsumerWidget {
  const PagesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pages = ref.watch(projectPagesProvider(project.id));
    final data = pages.value;
    if (data == null && !pages.isLoading && !pages.hasError) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Pages'),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.borderMd,
            border: Border.all(color: colors.border),
          ),
          child: AsyncValueWidget(
            value: pages,
            onRetry: () => ref.invalidate(projectPagesProvider(project.id)),
            data: (info) => Column(
              children: [
                if (info != null) ...[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.language, size: 18),
                    title: Text(
                      info.pages.url.isEmpty ? 'Pages site' : info.pages.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: info.pages.url.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Open site',
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed: () =>
                                unawaited(launchExternal(info.pages.url)),
                          ),
                  ),
                  Divider(height: 1, color: colors.border, indent: Insets.lg),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Force HTTPS'),
                    subtitle: const Text('Redirect all Pages traffic to HTTPS'),
                    value: info.pages.forceHttps,
                    onChanged: (v) => _update(context, ref, forceHttps: v),
                  ),
                  Divider(height: 1, color: colors.border, indent: Insets.lg),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Unique domain'),
                    subtitle: const Text(
                      'Serve this site on a unique per-deployment domain',
                    ),
                    value: info.pages.uniqueDomainEnabled,
                    onChanged: (v) =>
                        _update(context, ref, uniqueDomainEnabled: v),
                  ),
                ],
                for (final PageDomain d in info?.domains ?? const [])
                  Column(
                    children: [
                      Divider(
                        height: 1,
                        color: colors.border,
                        indent: Insets.lg,
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          d.verified
                              ? Icons.verified_outlined
                              : Icons.hourglass_empty,
                          size: 18,
                          color: d.verified ? colors.success : colors.inkFaint,
                        ),
                        title: Text(d.domain),
                        subtitle: Text(
                          [
                            d.verified ? 'Verified' : 'Unverified',
                            if (d.autoSslEnabled) 'Auto SSL',
                            if (d.expiresAt != null)
                              'cert expires ${Format.date(d.expiresAt)}',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove domain',
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                          ),
                          onPressed: () =>
                              _removeDomain(context, ref, d.domain),
                        ),
                      ),
                    ],
                  ),
                if (info != null) ...[
                  Divider(height: 1, color: colors.border, indent: Insets.lg),
                  Row(
                    children: [
                      const SizedBox(width: Insets.sm),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add domain'),
                        onPressed: () => _addDomain(context, ref),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: Icon(
                          Icons.unpublished_outlined,
                          size: 16,
                          color: colors.danger,
                        ),
                        label: Text(
                          'Unpublish',
                          style: TextStyle(color: colors.danger),
                        ),
                        onPressed: () => _unpublish(context, ref),
                      ),
                      const SizedBox(width: Insets.sm),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref, {
    bool? forceHttps,
    bool? uniqueDomainEnabled,
  }) async {
    try {
      await ref
          .read(projectsRepositoryProvider)
          .updatePages(
            project.id,
            forceHttps: forceHttps,
            uniqueDomainEnabled: uniqueDomainEnabled,
          );
      ref.invalidate(projectPagesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _addDomain(BuildContext context, WidgetRef ref) async {
    final domain = await showDialog<String>(
      context: context,
      builder: (context) => const _DomainDialog(),
    );
    if (domain == null || domain.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectsRepositoryProvider)
          .addPageDomain(project.id, domain);
      ref.invalidate(projectPagesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _removeDomain(
    BuildContext context,
    WidgetRef ref,
    String domain,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Remove domain?',
      body: '"$domain" will stop serving this Pages site.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(projectsRepositoryProvider)
          .deletePageDomain(project.id, domain);
      ref.invalidate(projectPagesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Unpublish Pages?',
      body: 'The site goes offline until the next Pages deployment.',
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(projectsRepositoryProvider).unpublishPages(project.id);
      ref.invalidate(projectPagesProvider(project.id));
    } on ApiException catch (e) {
      if (context.mounted) {
        showAdminError(context, e.message);
      }
    }
  }
}

class _DomainDialog extends StatefulWidget {
  const _DomainDialog();

  @override
  State<_DomainDialog> createState() => _DomainDialogState();
}

class _DomainDialogState extends State<_DomainDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Pages domain'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'docs.example.com',
          labelText: 'Domain',
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
