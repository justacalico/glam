import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/core/utils/debouncer.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/empty_state.dart';
import 'package:glam/src/core/widgets/paged_list_view.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/issues/presentation/issue_tile.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_tile.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/presentation/project_tile.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/search/application/search_providers.dart';
import 'package:glam/src/features/search/data/search_repository.dart';
import 'package:glam/src/features/search/domain/search_result.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';
import 'package:glam/src/features/snippets/presentation/snippets_screen.dart';
import 'package:glam/src/app/theme/app_typography.dart';

/// Global or container-scoped search. Pass [projectId] or [groupId] to
/// scope the scope list and the endpoint.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.projectId, this.groupId, super.key});

  final Object? projectId;
  final Object? groupId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer();
  String _term = '';
  late SearchScope _scope;

  List<SearchScope> get _scopes => widget.projectId != null
      ? SearchScope.projectScopes
      : widget.groupId != null
      ? SearchScope.groupScopes
      : SearchScope.globalScopes;

  @override
  void initState() {
    super.initState();
    _scope = _scopes.first;
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  SearchQuery get _query => (
    scope: _scope,
    term: _term,
    projectId: widget.projectId,
    groupId: widget.groupId,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final searching = _term.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 38,
          child: TextField(
            controller: _search,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                _debouncer(() => setState(() => _term = v.trim())),
            decoration: InputDecoration(
              hintText: 'Search',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              children: [
                for (final s in _scopes)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.sm),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: _scope == s,
                      onSelected: (_) => setState(() => _scope = s),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: searching ? _Results(query: _query) : const _Prompt(),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search,
      title: 'Search GitLab',
      message: 'Projects, issues, merge requests, code, and more.',
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final SearchQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(searchProvider(query));
    final notifier = ref.read(searchProvider(query).notifier);

    return AsyncValueWidget(
      value: state,
      onRetry: notifier.refresh,
      data: (data) => PagedListView(
        state: data,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        separator: Divider(height: 1, color: colors.border),
        empty: const EmptyState(icon: Icons.search_off, title: 'No results'),
        itemBuilder: (context, index) =>
            _ResultTile(item: data.items[index], scope: query.scope),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item, required this.scope});

  final Object item;
  final SearchScope scope;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final Project p => ProjectTile(
        project: p,
        onTap: () => unawaited(context.push(Routes.project(p.id))),
      ),
      final Issue i => IssueTile(
        issue: i,
        onTap: () =>
            unawaited(context.push(Routes.projectIssue(i.projectId, i.iid))),
      ),
      final MergeRequest m => MrTile(
        mr: m,
        onTap: () =>
            unawaited(context.push(Routes.projectMr(m.projectId, m.iid))),
      ),
      final Snippet s => SnippetTile(snippet: s),
      final BlobResult b => _BlobTile(blob: b, projectId: b.projectId),
      final Commit c => _CommitTile(commit: c),
      final Note n => _NoteTile(note: n),
      final Milestone m => _MilestoneTile(milestone: m),
      final GitLabUser u => _UserTile(user: u),
      _ => const SizedBox.shrink(),
    };
  }
}

class _BlobTile extends StatelessWidget {
  const _BlobTile({required this.blob, this.projectId});

  final BlobResult blob;
  final int? projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: projectId == null
          ? null
          : () => unawaited(
              context.push(
                Routes.projectBlob(projectId!, ref: blob.ref, path: blob.path),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 16,
                  color: colors.inkMuted,
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    blob.path,
                    style: const TextStyle(
                      fontFamily: GlamFonts.mono,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (blob.startLine != null)
                  Text(':${blob.startLine}', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Insets.sm),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: Radii.borderSm,
              ),
              child: Text(
                blob.data,
                style: const TextStyle(
                  fontFamily: GlamFonts.mono,
                  fontSize: 11.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitTile extends StatelessWidget {
  const _CommitTile({required this.commit});

  final Commit commit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ListTile(
      leading: Icon(Icons.commit, size: 18, color: colors.inkMuted),
      title: Text(
        commit.title,
        style: theme.textTheme.titleSmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${commit.shortId} · ${commit.authorName ?? ''} '
        '· ${Format.relative(commit.committedAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ListTile(
      leading: Icon(
        Icons.mode_comment_outlined,
        size: 18,
        color: colors.inkMuted,
      ),
      title: Text(
        note.body,
        style: theme.textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${note.author?.name ?? ''} · ${Format.relative(note.createdAt)}',
        maxLines: 1,
      ),
      dense: true,
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ListTile(
      leading: Icon(Icons.flag_outlined, size: 18, color: colors.inkMuted),
      title: Text(milestone.title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        milestone.dueDate != null
            ? 'Due ${Format.date(milestone.dueDate)}'
            : '',
      ),
      dense: true,
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final GitLabUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: UserAvatar(
        name: user.name,
        avatarUrl: user.avatarUrl,
        radius: 16,
      ),
      title: Text(user.name, style: theme.textTheme.titleSmall),
      subtitle: Text('@${user.username}'),
      dense: true,
      onTap: user.webUrl == null
          ? null
          : () => unawaited(launchExternal(user.webUrl!)),
    );
  }
}
