import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/models/note.dart';
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

    test('time_stats decodes estimate and spent', () {
      final mr = _first();
      expect(mr.timeEstimate, 7200);
      expect(mr.timeSpent, 1800);
      final flat = MergeRequest.fromJson(const {
        'time_estimate': 60,
        'total_time_spent': 30,
      });
      expect(flat.timeEstimate, 60);
      expect(flat.timeSpent, 30);
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

    test('time tracking posts the duration endpoints', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/merge_requests/7/time_estimate', const {})
        ..post('/projects/42/merge_requests/7/add_spent_time', const {})
        ..post('/projects/42/merge_requests/7/reset_spent_time', const {});
      final repo = MergeRequestsRepository(client);

      await repo.setTimeEstimate(42, 7, '2h');
      expect(adapter.lastRequest!.queryParameters['duration'], '2h');

      await repo.addTimeSpent(42, 7, '30m');
      expect(adapter.lastRequest!.queryParameters['duration'], '30m');
      expect(adapter.lastRequest!.path, contains('add_spent_time'));

      await repo.resetTimeSpent(42, 7);
      expect(adapter.lastRequest!.path, contains('reset_spent_time'));
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

    test('versions decodes the list with shortSha', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/versions',
        fixtureJson('mr_versions'),
      );
      final repo = MergeRequestsRepository(client);

      final versions = await repo.versions(42, 7);

      expect(versions, hasLength(2));
      expect(versions.first.shortSha, '11be37ce');
      expect(versions.first.state, 'collected');
      expect(versions.last.id, 128);
    });

    test('versionDiffs decodes the embedded diffs', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/versions/128',
        fixtureJson('mr_version_diff'),
      );
      final repo = MergeRequestsRepository(client);

      final diffs = await repo.versionDiffs(42, 7, 128);

      expect(diffs, hasLength(1));
      expect(diffs.first.newPath, 'lib/main.dart');
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

    test('mrPipelines lists and createMrPipeline posts', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/merge_requests/7/pipelines',
          fixtureJson('mr_pipelines'),
        )
        ..post(
          '/projects/42/merge_requests/7/pipelines',
          (fixtureJson('mr_pipelines') as List).first,
        );
      final repo = MergeRequestsRepository(client);

      final list = await repo.mrPipelines(42, 7);
      expect(list, hasLength(2));
      expect(list.first.id, 901);
      expect(list.first.source, 'merge_request_event');

      final created = await repo.createMrPipeline(42, 7);
      expect(created.id, 901);
      expect(
        adapter.requestsTo('POST', '/projects/42/merge_requests/7/pipelines'),
        hasLength(1),
      );
    });

    test('participants decodes users', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/participants',
        fixtureJson('participants'),
      );
      final repo = MergeRequestsRepository(client);

      final users = await repo.participants(42, 7);

      expect(users, hasLength(2));
      expect(users.first.username, 'jane');
    });

    test('closesIssues decodes issues', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/closes_issues',
        fixtureJson('issues'),
      );
      final repo = MergeRequestsRepository(client);

      final issues = await repo.closesIssues(42, 7);

      expect(issues, hasLength(2));
      expect(issues.first.iid, 12);
    });

    test('rawDiff returns patch text', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/merge_requests/7/raw_diffs',
        'diff --git a/x b/x\n+line',
      );
      final repo = MergeRequestsRepository(client);

      expect(await repo.rawDiff(42, 7), contains('diff --git'));
    });

    test('draft notes CRUD and publish hit their paths', () async {
      final (client, adapter) = testClient();
      final draft = (fixtureJson('draft_notes') as List).first;
      adapter
        ..get(
          '/projects/42/merge_requests/7/draft_notes',
          fixtureJson('draft_notes'),
        )
        ..post('/projects/42/merge_requests/7/draft_notes', draft)
        ..put('/projects/42/merge_requests/7/draft_notes/301', {
          ...draft as Map<String, dynamic>,
          'note': 'edited',
        })
        ..delete('/projects/42/merge_requests/7/draft_notes/301')
        ..put(
          '/projects/42/merge_requests/7/draft_notes/301/publish',
          null,
          status: 204,
        )
        ..post('/projects/42/merge_requests/7/draft_notes/bulk_publish', {});

      final repo = MergeRequestsRepository(client);

      final drafts = await repo.draftNotes(42, 7);
      expect(drafts, hasLength(2));
      expect(drafts.first.position?.newLine, 12);
      expect(drafts.last.resolveDiscussion, isTrue);

      final created = await repo.createDraftNote(42, 7, 'note text');
      expect(created.id, 301);
      final sent = adapter.requests
          .where((r) => r.method == 'POST' && r.path.endsWith('draft_notes'))
          .single;
      expect((sent.data as Map)['note'], 'note text');

      final edited = await repo.updateDraftNote(42, 7, 301, 'edited');
      expect(edited.note, 'edited');

      await repo.deleteDraftNote(42, 7, 301);
      await repo.publishDraftNote(42, 7, 301);
      await repo.publishAllDraftNotes(42, 7);

      expect(
        adapter.requestsTo(
          'POST',
          '/projects/42/merge_requests/7/draft_notes/bulk_publish',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'PUT',
          '/projects/42/merge_requests/7/draft_notes/301/publish',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/merge_requests/7/draft_notes/301',
        ),
        hasLength(1),
      );
    });

    test('createDraftNote sends the position body', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/merge_requests/7/draft_notes',
        (fixtureJson('draft_notes') as List).first,
      );
      final repo = MergeRequestsRepository(client);

      await repo.createDraftNote(
        42,
        7,
        'pinned',
        position: const NotePosition(
          baseSha: 'a',
          startSha: 'a',
          headSha: 'b',
          oldPath: 'lib/a.dart',
          newPath: 'lib/a.dart',
          newLine: 12,
        ),
      );

      final sent = adapter.requests
          .where((r) => r.method == 'POST' && r.path.endsWith('draft_notes'))
          .single;
      final position = (sent.data as Map)['position'] as Map;
      expect(position['position_type'], 'text');
      expect(position['new_line'], 12);
      expect(position.containsKey('old_line'), isFalse);
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

    test('mrVersionsProvider and mrVersionDiffsProvider load', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/versions',
          fixtureJson('mr_versions'),
        )
        ..get(
          '/projects/42/merge_requests/7/versions/128',
          fixtureJson('mr_version_diff'),
        );

      const loc = (project: 42, iid: 7);
      final versions = await container.read(mrVersionsProvider(loc).future);
      final diffs = await container.read(
        mrVersionDiffsProvider((mr: loc, versionId: 128)).future,
      );

      expect(versions, hasLength(2));
      expect(diffs, hasLength(1));
    });

    test('mrPipelinesProvider and mrParticipantsProvider load', () async {
      adapter
        ..get(
          '/projects/42/merge_requests/7/pipelines',
          fixtureJson('mr_pipelines'),
        )
        ..get(
          '/projects/42/merge_requests/7/participants',
          fixtureJson('participants'),
        );

      const loc = (project: 42, iid: 7);
      final pipelines = await container.read(mrPipelinesProvider(loc).future);
      final people = await container.read(mrParticipantsProvider(loc).future);

      expect(pipelines, hasLength(2));
      expect(people, hasLength(2));
    });

    test('mrDraftNotesProvider queues, edits, removes and publishes', () async {
      final drafts = fixtureJson('draft_notes') as List;
      adapter
        ..get('/projects/42/merge_requests/7/draft_notes', drafts)
        ..get('/projects/42/merge_requests/7/discussions', const [])
        ..get(
          '/projects/42/merge_requests/7/participants',
          fixtureJson('participants'),
        )
        ..post('/projects/42/merge_requests/7/draft_notes', {
          ...drafts.first as Map<String, dynamic>,
          'id': 303,
          'note': 'queued',
        })
        ..put('/projects/42/merge_requests/7/draft_notes/301', {
          ...drafts.first as Map<String, dynamic>,
          'note': 'edited',
        })
        ..delete('/projects/42/merge_requests/7/draft_notes/301')
        ..delete('/projects/42/merge_requests/7/draft_notes/302')
        ..put(
          '/projects/42/merge_requests/7/draft_notes/301/publish',
          null,
          status: 204,
        )
        ..post('/projects/42/merge_requests/7/draft_notes/bulk_publish', {});

      const loc = (project: 42, iid: 7);
      final notifier = container.read(mrDraftNotesProvider(loc).notifier);
      var state = await container.read(mrDraftNotesProvider(loc).future);
      expect(state, hasLength(2));

      await notifier.add('queued');
      state = container.read(mrDraftNotesProvider(loc)).value!;
      expect(state, hasLength(3));

      await notifier.edit(state.first, 'edited');
      state = container.read(mrDraftNotesProvider(loc)).value!;
      expect(state.first.note, 'edited');
      expect(state, hasLength(3));

      await notifier.publish(only: state.first);
      state = container.read(mrDraftNotesProvider(loc)).value!;
      expect(state, hasLength(2));
      expect(
        adapter.requestsTo(
          'PUT',
          '/projects/42/merge_requests/7/draft_notes/301/publish',
        ),
        hasLength(1),
      );

      await notifier.remove(state.first);
      state = container.read(mrDraftNotesProvider(loc)).value!;
      expect(state, hasLength(1));

      await notifier.publish();
      state = container.read(mrDraftNotesProvider(loc)).value!;
      expect(state, isEmpty);
      expect(
        adapter.requestsTo(
          'POST',
          '/projects/42/merge_requests/7/draft_notes/bulk_publish',
        ),
        hasLength(1),
      );
    });

    test('publish falls back to per-draft PUT when bulk 404s', () async {
      final drafts = fixtureJson('draft_notes') as List;
      adapter
        ..get('/projects/42/merge_requests/7/draft_notes', drafts)
        ..get('/projects/42/merge_requests/7/discussions', const [])
        ..get(
          '/projects/42/merge_requests/7/participants',
          fixtureJson('participants'),
        )
        ..post('/projects/42/merge_requests/7/draft_notes/bulk_publish', {
          'message': 'Not Found',
        }, status: 404)
        ..put(
          '/projects/42/merge_requests/7/draft_notes/301/publish',
          null,
          status: 204,
        )
        ..put(
          '/projects/42/merge_requests/7/draft_notes/302/publish',
          null,
          status: 204,
        );

      const loc = (project: 42, iid: 7);
      final notifier = container.read(mrDraftNotesProvider(loc).notifier);
      await container.read(mrDraftNotesProvider(loc).future);

      await notifier.publish();
      expect(container.read(mrDraftNotesProvider(loc)).value!, isEmpty);
      expect(
        adapter.requestsTo(
          'PUT',
          '/projects/42/merge_requests/7/draft_notes/301/publish',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'PUT',
          '/projects/42/merge_requests/7/draft_notes/302/publish',
        ),
        hasLength(1),
      );
    });
  });
}
