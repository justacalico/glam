import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Fills a description from a `.gitlab/` template. Renders nothing
/// when the project has no templates of [type] (`issues` or
/// `merge_requests`).
class DescriptionTemplatePicker extends ConsumerWidget {
  const DescriptionTemplatePicker({
    required this.projectId,
    required this.type,
    required this.onApply,
    super.key,
  });

  final Object projectId;
  final String type;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(
      descriptionTemplatesProvider((project: projectId, type: type)),
    );
    final items = templates.value ?? const <DescriptionTemplate>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        icon: const Icon(Icons.article_outlined, size: 16),
        label: Text(context.l10n.templateUse),
        onPressed: () => unawaited(_pick(context, items)),
      ),
    );
  }

  Future<void> _pick(BuildContext context, List<DescriptionTemplate> items) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors = context.colors;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  0,
                  Insets.lg,
                  Insets.sm,
                ),
                child: Text(
                  context.l10n.templateChoose,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final t in items)
                ListTile(
                  dense: true,
                  title: Text(t.name),
                  subtitle: Text(
                    t.content.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.inkFaint, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onApply(t.content);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
