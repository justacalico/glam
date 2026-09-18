import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/features/repository/application/repository_providers.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/repository/presentation/changes_list.dart';
import 'package:glam/src/features/repository/presentation/commits_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_typography.dart';
import 'package:glam/src/core/utils/l10n.dart';

/// Compare two refs: the commits `to` adds over `from` plus the diff.
/// `from`/`to` arrive via route query params; both are editable here.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({required this.projectId, this.from, this.to, super.key});

  final String projectId;
  final String? from;
  final String? to;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _from;
  String? _to;
  var _prefilled = false;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  @override
  void didUpdateWidget(CompareScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _from = widget.from;
      _to = widget.to;
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(
      branchesProvider((project: widget.projectId, search: null)),
    );
    final tags = ref.watch(
      tagsProvider((project: widget.projectId, search: null)),
    );
    final branchItems = branches.value?.items ?? const <Branch>[];
    final tagItems = tags.value?.items ?? const <Tag>[];
    // The base defaults to the project's default branch once it loads.
    if (!_prefilled && branchItems.isNotEmpty) {
      _prefilled = true;
      _from ??= branchItems
          .firstWhere((b) => b.isDefault, orElse: () => branchItems.first)
          .name;
    }
    // A picked tag/sha may be missing from the first branch page.
    final refs = <String>{
      for (final b in branchItems) b.name,
      for (final t in tagItems) t.name,
      ?_from,
      ?_to,
    }.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compare)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              Insets.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RefPicker(
                    label: context.l10n.base,
                    value: _from,
                    refs: refs,
                    onChanged: (v) => setState(() => _from = v),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.swapRefs,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  onPressed: _from == null || _to == null
                      ? null
                      : () => setState(() {
                          final f = _from;
                          _from = _to;
                          _to = f;
                        }),
                ),
                Expanded(
                  child: _RefPicker(
                    label: context.l10n.compare,
                    value: _to,
                    refs: refs,
                    onChanged: (v) => setState(() => _to = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      return EmptyState(
        icon: Icons.compare_arrows,
        title: context.l10n.pickTwoRefs,
        message: context.l10n.branchesTagsOrCommitShas,
      );
    }
    final loc = (project: widget.projectId as Object, from: from, to: to);
    return AsyncValueWidget<CompareResult>(
      value: ref.watch(compareProvider(loc)),
      onRetry: () => ref.invalidate(compareProvider(loc)),
      wrapRefresh: true,
      data: (result) =>
          _CompareResult(result: result, projectId: widget.projectId, loc: loc),
    );
  }
}

class _RefPicker extends StatelessWidget {
  const _RefPicker({
    required this.label,
    required this.value,
    required this.refs,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> refs;
  final ValueChanged<String?> onChanged;

  Future<void> _enterCustom(BuildContext context) async {
    final controller = TextEditingController();
    final ref = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.enterARef),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.branchTagOrCommitSha,
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.useRef),
          ),
        ],
      ),
    );
    final trimmed = ref?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      onChanged(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Insets.sm,
                vertical: Insets.sm,
              ),
            ),
            items: [
              for (final r in refs)
                DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: GlamFonts.mono,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
        IconButton(
          tooltip: context.l10n.enterARef,
          iconSize: 16,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _enterCustom(context),
        ),
      ],
    );
  }
}

class _CompareResult extends ConsumerWidget {
  const _CompareResult({
    required this.result,
    required this.projectId,
    required this.loc,
  });

  final CompareResult result;
  final String projectId;
  final CompareLocation loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final mergeBase = ref.watch(mergeBaseProvider(loc)).value;
    return ListView(
      padding: Insets.pagePadding,
      children: [
        if (result.compareSameRef)
          _Banner(
            icon: Icons.check_circle_outline,
            text: context.l10n.theseRefsPointAtTheSame,
            color: colors.success,
          ),
        if (result.compareTimeout)
          _Banner(
            icon: Icons.timer_outlined,
            text: context.l10n.comparisonTimedOutResultsMayBe,
            color: colors.warning,
          ),
        if (mergeBase != null && !result.compareSameRef)
          InkWell(
            borderRadius: Radii.borderMd,
            onTap: () => unawaited(
              context.push(Routes.projectCommit(projectId, mergeBase.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: context.l10n.mergeBasePrefix),
                    TextSpan(
                      text: mergeBase.shortId,
                      style: const TextStyle(fontFamily: GlamFonts.mono),
                    ),
                    if (mergeBase.title.isNotEmpty)
                      TextSpan(text: context.l10n.titleSuffix(mergeBase.title)),
                  ],
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        Text(
          '${result.commits.length} '
          '${result.commits.length == 1 ? 'commit' : 'commits'}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: Insets.sm),
        if (result.commits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            child: Text(
              context.l10n.nothingNewOnTheCompareRef,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          for (final commit in result.commits)
            CommitTile(commit: commit, projectId: projectId),
        const SizedBox(height: Insets.lg),
        ChangesList(changes: result.diffs),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.md),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Radii.borderMd,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
