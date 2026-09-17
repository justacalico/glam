import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

MergeRequest _first() => MergeRequest.fromJson(
  (fixtureJson('mrs') as List).first as Map<String, dynamic>,
);

void main() {
  group('MergeRequest model', () {
    test('parses branches, pipeline, diff refs', () {
      final mr = _first();
      expect(mr.iid, 7);
      expect(mr.sourceBranch, 'feature/files');
      expect(mr.targetBranch, 'main');
      expect(mr.isOpen, isTrue);
      expect(mr.headPipeline?.status, 'success');
      expect(mr.diffRefs?.headSha, '61049424');
      expect(mr.mergeabilityLabel, 'Ready to merge');
      expect(mr.reviewers.single.username, 'john');
    });

    test('merged MR exposes merged_by and merge commit', () {
      final mr = MergeRequest.fromJson(
        (fixtureJson('mrs') as List).last as Map<String, dynamic>,
      );
      expect(mr.isMerged, isTrue);
      expect(mr.mergedBy?.name, 'Jane Doe');
      expect(mr.mergeCommitSha, 'deadbeef');
      expect(mr.mergeabilityLabel, 'Cannot merge');
    });

    test('work_in_progress maps to draft', () {
      final mr = MergeRequest.fromJson(const {'work_in_progress': true});
      expect(mr.draft, isTrue);
    });

    test('not_approved maps to a readable label', () {
      final mr = MergeRequest.fromJson(const {
        'state': 'opened',
        'detailed_merge_status': 'not_approved',
      });
      expect(mr.mergeabilityLabel, 'Needs approval');
    });
  });

  group('stripDraftPrefix', () {
    test('removes colon, bracketed and stacked prefixes', () {
      expect(stripDraftPrefix('Draft: Add files'), 'Add files');
      expect(stripDraftPrefix('[Draft] Add files'), 'Add files');
      expect(stripDraftPrefix('(wip) Add files'), 'Add files');
      expect(stripDraftPrefix('WIP - Add files'), 'Add files');
      expect(stripDraftPrefix('Draft: Draft: Add files'), 'Add files');
    });

    test('leaves non-draft titles and mid-title markers alone', () {
      expect(stripDraftPrefix('Add files'), 'Add files');
      expect(stripDraftPrefix('fix draft: handling'), 'fix draft: handling');
    });
  });

  group('MergeRequestsRepository', () {
    test('lists MRs with scope filter', () async {
      final (client, adapter) = testClient();
      adapter.get('/merge_requests', fixtureJson('mrs'));
      final repo = MergeRequestsRepository(client);

      final page = await repo.mergeRequests(scope: MrScope.created);

      expect(page.items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['scope'], 'created_by_me');
    });

    test('review scope maps to reviewer_id=self', () async {
      final (client, adapter) = testClient();
      adapter.get('/merge_requests', const []);
      final repo = MergeRequestsRepository(client);

      await repo.mergeRequests(scope: MrScope.review);

      final query = adapter.lastRequest!.queryParameters;
      expect(query['reviewer_id'], 'self');
      expect(query['scope'], 'all');
    });

    test('projectMergeRequests hits project endpoint', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/merge_requests', fixtureJson('mrs'));
      final repo = MergeRequestsRepository(client);

      final page = await repo.projectMergeRequests(
        42,
        state: 'merged',
        targetBranch: 'main',
      );

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['state'], 'merged');
      expect(query['target_branch'], 'main');
    });

    test('changes decodes the wrapped list', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/merge_requests/7/changes', {
        'changes': fixtureJson('commit_diff'),
      });
      final repo = MergeRequestsRepository(client);

      final changes = await repo.changes(42, 7);

      expect(changes, hasLength(2));
      expect(changes.first.newPath, 'lib/main.dart');
    });

    test('merge puts the merge options', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/merge_requests/7/merge',
        (fixtureJson('mrs') as List).last,
      );
      final repo = MergeRequestsRepository(client);

      final mr = await repo.merge(
        42,
        7,
        squash: true,
        removeSourceBranch: true,
        sha: 'abc',
      );

      expect(mr.isMerged, isTrue);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['squash'], true);
      expect(sent['should_remove_source_branch'], true);
      expect(sent['sha'], 'abc');
    });

    test('merge with mergeWhenPipelineSucceeds and its cancel', () async {
      final (client, adapter) = testClient();
      adapter
        ..put(
          '/projects/42/merge_requests/7/merge',
          (fixtureJson('mrs') as List).last,
        )
        ..post(
          '/projects/42/merge_requests/7/cancel_merge_when_pipeline_succeeds',
          {},
        );
      final repo = MergeRequestsRepository(client);

      await repo.merge(42, 7, mergeWhenPipelineSucceeds: true);
      expect(
        (adapter.lastRequest!.data as Map)['merge_when_pipeline_succeeds'],
        true,
      );

      await repo.cancelAutoMerge(42, 7);
      expect(
        adapter.requestsTo(
          'POST',
          '/projects/42/merge_requests/7/cancel_merge_when_pipeline_succeeds',
        ),
        hasLength(1),
      );
    });

    test('approve and unapprove post to the right paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/merge_requests/7/approve', {})
        ..post('/projects/42/merge_requests/7/unapprove', {});
      final repo = MergeRequestsRepository(client);

      await repo.approve(42, 7);
      await repo.unapprove(42, 7);

      expect(
        adapter.requestsTo('POST', '/projects/42/merge_requests/7/approve'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/merge_requests/7/unapprove'),
        hasLength(1),
      );
    });

    test('approvals decodes the state', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/merge_requests/7/approvals', {
        'approved': true,
        'approvals_required': 2,
        'approvals_left': 0,
        'user_has_approved': true,
        'user_can_approve': false,
        'approved_by': [
          {
            'user': {'id': 8, 'name': 'John Smith', 'username': 'john'},
          },
        ],
      });
      final repo = MergeRequestsRepository(client);

      final state = await repo.approvals(42, 7);

      expect(state.approved, isTrue);
      expect(state.approvedBy.single.name, 'John Smith');
      expect(state.userHasApproved, isTrue);
      expect(state.userCanApprove, isFalse);
    });

    test('createMergeRequest posts branches and flags', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests',
        (fixtureJson('mrs') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      final mr = await repo.createMergeRequest(
        42,
        sourceBranch: 'feat',
        targetBranch: 'main',
        title: 'New MR',
        squash: true,
        removeSourceBranch: true,
      );

      expect(mr.iid, 7);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['source_branch'], 'feat');
      expect(sent['remove_source_branch'], true);
    });

    test('createMergeRequest posts assignee and reviewer ids', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests',
        (fixtureJson('mrs') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.createMergeRequest(
        42,
        sourceBranch: 'feat',
        targetBranch: 'main',
        title: 'New MR',
        assigneeIds: const [5, 9],
        reviewerIds: const [12],
      );

      final sent = adapter.lastRequest!.data as Map;
      expect(sent['assignee_ids'], [5, 9]);
      expect(sent['reviewer_ids'], [12]);
    });

    test('updateMergeRequest puts people ids and state event', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/merge_requests/7',
        (fixtureJson('mrs') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.updateMergeRequest(
        42,
        7,
        title: 'Draft: Renamed',
        assigneeIds: const [5],
        reviewerIds: const [],
      );

      final sent = adapter.lastRequest!.data as Map;
      expect(sent['title'], 'Draft: Renamed');
      expect(sent['assignee_ids'], [5]);
      expect(sent['reviewer_ids'], isEmpty);
    });

    test('rebase puts to the rebase endpoint', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/merge_requests/7/rebase',
        (fixtureJson('mrs') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.rebase(42, 7);

      expect(
        adapter.requestsTo('PUT', '/projects/42/merge_requests/7/rebase'),
        hasLength(1),
      );
    });
  });

  group('providers', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          mrRepositoryProvider.overrideWithValue(
            MergeRequestsRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('mergeRequestsProvider loads the filtered list', () async {
      adapter.get('/merge_requests', fixtureJson('mrs'));

      final state = await container.read(mergeRequestsProvider.future);

      expect(state.items, hasLength(2));
      expect(state.items.first.title, 'Add file browser');
    });

    test('filter changes refetch', () async {
      adapter.get('/merge_requests', fixtureJson('mrs'));
      await container.read(mergeRequestsProvider.future);

      container.read(mrFilterProvider.notifier).update((
        scope: MrScope.all,
        state: 'merged',
        search: 'x',
      ));
      await container.read(mergeRequestsProvider.future);

      expect(adapter.lastRequest!.queryParameters['state'], 'merged');
    });

    test('mrProvider and mrChangesProvider fetch detail', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7',
          (fixtureJson('mrs') as List).first,
        )
        ..get('/projects/42/merge_requests/7/changes', {
          'changes': fixtureJson('commit_diff'),
        });

      const loc = (project: 42, iid: 7);
      final mr = await container.read(mrProvider(loc).future);
      final changes = await container.read(mrChangesProvider(loc).future);

      expect(mr.sourceBranch, 'feature/files');
      expect(changes, hasLength(2));
    });
  });
}
