import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('issues', () {
    test('lists issues with scope/state/search params', () async {
      final (client, adapter) = testClient();
      adapter.get('/issues', fixtureJson('issues'));
      final repo = IssuesRepository(client);

      final page = await repo.issues(
        scope: IssueScope.created,
        state: 'closed',
        search: 'slow',
      );

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['scope'], 'created_by_me');
      expect(query['state'], 'closed');
      expect(query['search'], 'slow');
    });

    test('defaults to assigned scope', () async {
      final (client, adapter) = testClient();
      adapter.get('/issues', const []);
      final repo = IssuesRepository(client);

      await repo.issues();

      expect(adapter.lastRequest!.queryParameters['scope'], 'assigned_to_me');
    });
  });

  group('projectIssues', () {
    test('hits the project endpoint with filters', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/issues', fixtureJson('issues'));
      final repo = IssuesRepository(client);

      final page = await repo.projectIssues(
        42,
        state: 'opened',
        labels: 'bug',
        milestoneId: 5,
        assigneeId: 8,
      );

      expect(page.items.first.title, contains('File tree'));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['labels'], 'bug');
      expect(query['milestone'], '5');
      expect(query['assignee_id'], '8');
    });
  });

  group('issue', () {
    test('fetches one issue by iid', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/issues/12',
        (fixtureJson('issues') as List).first,
      );
      final repo = IssuesRepository(client);

      final issue = await repo.issue(42, 12);

      expect(issue.iid, 12);
      expect(issue.isOpen, isTrue);
      expect(issue.labels, ['bug', 'frontend']);
      expect(issue.taskStatus, '1/4');
      expect(issue.milestone?.title, 'v1.3');
      expect(issue.assignees.single.username, 'john');
    });
  });

  group('create/update', () {
    test('createIssue posts fields', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/issues',
        (fixtureJson('issues') as List).first,
      );
      final repo = IssuesRepository(client);

      final issue = await repo.createIssue(
        42,
        title: 'New bug',
        description: 'details',
        labels: ['bug'],
        assigneeIds: [8],
        milestoneId: 5,
        dueDate: '2025-09-01',
        weight: 3,
        confidential: true,
      );

      expect(issue.iid, 12);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['title'], 'New bug');
      expect(sent['labels'], 'bug');
      expect(sent['assignee_ids'], [8]);
      expect(sent['confidential'], true);
    });

    test('updateIssue sends state_event for close', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/issues/12',
        (fixtureJson('issues') as List).last,
      );
      final repo = IssuesRepository(client);

      final issue = await repo.updateIssue(42, 12, stateEvent: 'close');

      expect(issue.isOpen, isFalse);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['state_event'], 'close');
    });

    test('updateIssue sends weight', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/issues/12',
        (fixtureJson('issues') as List).last,
      );
      final repo = IssuesRepository(client);

      await repo.updateIssue(42, 12, weight: 3);
      expect((adapter.lastRequest!.data as Map)['weight'], 3);
    });

    test('clone and move return the resulting issue', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/issues/12/clone',
          (fixtureJson('issues') as List).first,
        )
        ..post(
          '/projects/42/issues/12/move',
          (fixtureJson('issues') as List).first,
        );
      final repo = IssuesRepository(client);

      final copy = await repo.cloneIssue(42, 12, toProjectId: 42);
      expect(copy.title, isNotEmpty);
      expect((adapter.lastRequest!.data as Map)['to_project_id'], 42);

      final moved = await repo.moveIssue(42, 12, 77);
      expect(moved.title, isNotEmpty);
      expect((adapter.lastRequest!.data as Map)['to_project_id'], 77);
    });
  });

  group('notes', () {
    test('lists notes oldest first', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/issues/12/notes', fixtureJson('notes'));
      final repo = IssuesRepository(client);

      final page = await repo.notes(42, 12);

      expect(page.items, hasLength(2));
      expect(page.items[0].system, isFalse);
      expect(page.items[1].system, isTrue);
      expect(adapter.lastRequest!.queryParameters['sort'], 'asc');
    });

    test('addNote posts the body', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/issues/12/notes',
        (fixtureJson('notes') as List).first,
      );
      final repo = IssuesRepository(client);

      final note = await repo.addNote(42, 12, 'hello');

      expect(note.body, 'Reproduced on Android 15.');
      expect((adapter.lastRequest!.data as Map)['body'], 'hello');
    });

    test('updateNote puts and deleteNote deletes', () async {
      final (client, adapter) = testClient();
      adapter
        ..put(
          '/projects/42/issues/12/notes/501',
          (fixtureJson('notes') as List).first,
        )
        ..delete('/projects/42/issues/12/notes/501');
      final repo = IssuesRepository(client);

      await repo.updateNote(42, 12, 501, 'edited');
      await repo.deleteNote(42, 12, 501);

      expect(
        adapter.requestsTo('PUT', '/projects/42/issues/12/notes/501'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('DELETE', '/projects/42/issues/12/notes/501'),
        hasLength(1),
      );
    });
  });

  test('issue links list, link, unlink', () async {
    final (client, adapter) = testClient();
    final linkRows = fixtureJson('issue_links') as List;
    adapter
      ..get('/projects/42/issues/12/links', linkRows)
      // POST /links returns {id, link_type, source_issue, target_issue}
      // — a different shape from the GET list rows.
      ..post('/projects/42/issues/12/links', {
        'id': 200,
        'link_type': 'blocks',
        'source_issue': linkRows.first,
        'target_issue': linkRows.last,
      })
      ..delete('/projects/42/issues/12/links/100');
    final repo = IssuesRepository(client);

    final links = await repo.issueLinks(42, 12);
    expect(links, hasLength(2));
    expect(links.first.linkType, 'relates_to');
    expect(links.last.linkType, 'blocks');
    expect(links.last.typeLabel, 'Blocks');
    expect(links.first.linkId, 100);
    expect(links.first.issue.title, isNotEmpty);

    final created = await repo.linkIssue(
      42,
      12,
      targetProject: 'group/other',
      targetIid: 9,
      linkType: 'blocks',
    );
    expect(created.linkId, 200);
    expect(created.linkType, 'blocks');
    expect(created.issue.title, isNotEmpty);
    final sent = adapter.lastRequest!.data as Map;
    expect(sent['target_project_id'], 'group/other');
    expect(sent['target_issue_iid'], 9);
    expect(sent['link_type'], 'blocks');

    await repo.unlinkIssue(42, 12, 100);
    expect(
      adapter.requestsTo('DELETE', '/projects/42/issues/12/links/100'),
      hasLength(1),
    );
  });

  test('related merge requests parse as MRs', () async {
    final (client, adapter) = testClient();
    adapter.get(
      '/projects/42/issues/12/related_merge_requests',
      fixtureJson('related_mrs'),
    );
    final repo = IssuesRepository(client);

    final mrs = await repo.relatedMergeRequests(42, 12);
    expect(mrs, hasLength(2));
    expect(mrs.first.iid, greaterThan(0));
    expect(mrs.first.title, isNotEmpty);
  });

  test('participants decodes users', () async {
    final (client, adapter) = testClient();
    adapter.get(
      '/projects/42/issues/12/participants',
      fixtureJson('members'),
    );
    final repo = IssuesRepository(client);

    final users = await repo.participants(42, 12);

    expect(users, isNotEmpty);
    expect(users.first.name, isNotEmpty);
  });

  group('Issue model', () {
    test('closed issue parses closed_by and confidentiality', () {
      final closed = Issue.fromJson(
        (fixtureJson('issues') as List).last as Map<String, dynamic>,
      );
      expect(closed.isOpen, isFalse);
      expect(closed.confidential, isTrue);
      expect(closed.closedBy?.name, 'Jane Doe');
      expect(closed.references, isNull);
    });
  });
}
