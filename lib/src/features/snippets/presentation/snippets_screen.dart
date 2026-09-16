import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/utils/debouncer.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/features/snippets/application/snippets_providers.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';
import 'package:glam/src/features/snippets/presentation/snippet_form_screen.dart';

/// Personal + public snippets with search and a create button.
class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer();
  var _scope = SnippetScope.mine;
  String? _query;

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  SnippetFilter get _filter => (scope: _scope, search: _query);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(snippetsProvider(_filter));
    final notifier = ref.read(snippetsProvider(_filter).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snippets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: SegmentedButton<SnippetScope>(
                  segments: const [
                    ButtonSegment(
                      value: SnippetScope.mine,
                      label: Text('Yours'),
                    ),
                    ButtonSegment(
                      value: SnippetScope.public,
                      label: Text('Explore'),
                    ),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (s) => setState(() => _scope = s.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: Insets.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => _debouncer(
                      () => setState(() => _query = v.isEmpty ? null : v),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search snippets',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: colors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: Radii.borderMd,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Insets.sm),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New snippet',
        onPressed: () => unawaited(
          SnippetFormScreen.show(context).then((saved) {
            if (saved) {
              ref.invalidate(snippetsProvider);
            }
          }),
        ),
        child: const Icon(Icons.add),
      ),
      body: AsyncValueWidget(
        value: state,
        onRetry: notifier.refresh,
        data: (data) => PagedListView(
          state: data,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          separator: Divider(
            height: 1,
            color: colors.border,
            indent: Insets.lg,
          ),
          empty: const EmptyState(
            icon: Icons.notes_outlined,
            title: 'No snippets yet',
          ),
          itemBuilder: (context, index) =>
              SnippetTile(snippet: data.items[index]),
        ),
      ),
    );
  }
}

/// Snippets tab inside project detail, with a new-snippet button.
class ProjectSnippetsTab extends ConsumerWidget {
  const ProjectSnippetsTab({required this.projectId, super.key});

  final Object projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final list = ref.watch(projectSnippetsProvider(projectId));
    final notifier = ref.read(projectSnippetsProvider(projectId).notifier);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xs,
            ),
            child: IconButton(
              tooltip: 'New snippet',
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(
                SnippetFormScreen.show(context, projectId: projectId).then((
                  saved,
                ) {
                  if (saved) {
                    ref.invalidate(projectSnippetsProvider);
                  }
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget(
            value: list,
            onRetry: notifier.refresh,
            data: (data) => PagedListView(
              state: data,
              onLoadMore: notifier.loadMore,
              onRefresh: notifier.refresh,
              padding: const EdgeInsets.symmetric(vertical: Insets.sm),
              separator: Divider(
                height: 1,
                color: colors.border,
                indent: Insets.lg,
              ),
              empty: const EmptyState(
                icon: Icons.notes_outlined,
                title: 'No snippets',
              ),
              itemBuilder: (context, index) =>
                  SnippetTile(snippet: data.items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Snippet row shared by the global list and the project tab.
class SnippetTile extends StatelessWidget {
  const SnippetTile({required this.snippet, super.key});

  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final meta = [
      if (snippet.fileName != null) snippet.fileName!,
      if (snippet.author != null) snippet.author!.username,
      Format.relative(snippet.updatedAt),
    ].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: () => unawaited(
        context.push(
          '/snippets/${snippet.id}'
          '${snippet.projectId != null ? '?project=${snippet.projectId}' : ''}',
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            Icon(Icons.code, size: 20, color: colors.inkMuted),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snippet.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (snippet.visibility == 'private')
              Icon(Icons.lock_outline, size: 15, color: colors.inkFaint),
            Icon(Icons.chevron_right, size: 18, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}
