import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  late FakeDioAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    final (client, a) = testClient();
    adapter = a;
    container = ProviderContainer(
      overrides: [
        issuesRepositoryProvider.overrideWithValue(IssuesRepository(client)),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('issuesProvider loads the filtered list', () async {
    adapter.get('/issues', fixtureJson('issues'));

    final state = await container.read(issuesProvider.future);

    expect(state.items, hasLength(2));
    expect(state.items.first.title, contains('File tree'));
  });

  test('filter changes trigger a refetch', () async {
    adapter.get('/issues', fixtureJson('issues'));
    await container.read(issuesProvider.future);

    container.read(issueFilterProvider.notifier).update((
      scope: IssueScope.all,
      state: 'closed',
      search: 'x',
      issueType: 'incident',
      confidential: null,
      orderBy: null,
      sort: null,
    ));
    await container.read(issuesProvider.future);

    final query = adapter.lastRequest!.queryParameters;
    expect(query['scope'], 'all');
    expect(query['search'], 'x');
    expect(query['issue_type'], 'incident');
  });

  test('projectIssuesProvider is scoped per filter', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (
      project: 9,
      state: 'opened',
      search: null,
      label: null,
      milestone: null,
      issueType: null,
      assigneeId: null,
      authorId: null,
      confidential: null,
      orderBy: null,
      sort: null,
    );
    final state = await container.read(projectIssuesProvider(filter).future);

    expect(state.items, hasLength(2));
    expect(adapter.lastRequest!.queryParameters['state'], 'opened');
  });

  test('projectIssuesProvider forwards label and milestone', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (
      project: 9,
      state: null,
      search: null,
      label: 'bug',
      milestone: 'v1',
      issueType: null,
      assigneeId: null,
      authorId: null,
      confidential: null,
      orderBy: null,
      sort: null,
    );
    await container.read(projectIssuesProvider(filter).future);

    final query = adapter.lastRequest!.queryParameters;
    expect(query['labels'], 'bug');
    expect(query['milestone'], 'v1');
  });

  test('projectIssuesProvider forwards the assignee filter', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (
      project: 9,
      state: null,
      search: null,
      label: null,
      milestone: null,
      issueType: null,
      assigneeId: 7,
      authorId: null,
      confidential: null,
      orderBy: null,
      sort: null,
    );
    await container.read(projectIssuesProvider(filter).future);

    expect(adapter.lastRequest!.queryParameters['assignee_id'], '7');
  });

  test('projectIssuesProvider forwards the sort pair', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (
      project: 9,
      state: null,
      search: null,
      label: null,
      milestone: null,
      issueType: null,
      assigneeId: null,
      authorId: null,
      confidential: null,
      orderBy: 'due_date',
      sort: 'asc',
    );
    await container.read(projectIssuesProvider(filter).future);

    final query = adapter.lastRequest!.queryParameters;
    expect(query['order_by'], 'due_date');
    expect(query['sort'], 'asc');
  });

  test('projectIssuesProvider forwards the author filter', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (
      project: 9,
      state: null,
      search: null,
      label: null,
      milestone: null,
      issueType: null,
      assigneeId: null,
      authorId: 4,
      confidential: null,
      orderBy: null,
      sort: null,
    );
    await container.read(projectIssuesProvider(filter).future);

    expect(adapter.lastRequest!.queryParameters['author_id'], '4');
  });

  test('forwards the confidential filter', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));
    const filter = (
      project: 9,
      state: null,
      search: null,
      label: null,
      milestone: null,
      issueType: null,
      assigneeId: null,
      authorId: null,
      confidential: true,
      orderBy: null,
      sort: null,
    );
    await container.read(projectIssuesProvider(filter).future);

    expect(adapter.lastRequest!.queryParameters['confidential'], true);
  });

  test('issueProvider loads a single issue', () async {
    adapter.get('/projects/9/issues/12', (fixtureJson('issues') as List).first);

    const loc = (project: 9, iid: 12);
    final issue = await container.read(issueProvider(loc).future);

    expect(issue.title, contains('File tree'));
  });

  test('issueNotesProvider loads notes and addComment refreshes', () async {
    adapter
      ..get('/projects/9/issues/12/notes', fixtureJson('notes'))
      ..get('/projects/9/issues/12/notes', fixtureJson('notes'))
      ..post(
        '/projects/9/issues/12/notes',
        (fixtureJson('notes') as List).first,
      );

    const loc = (project: 9, iid: 12);
    final state = await container.read(issueNotesProvider(loc).future);
    expect(state.items, hasLength(2));

    await container.read(issueNotesProvider(loc).notifier).addComment('hi');

    expect(
      adapter.requestsTo('POST', '/projects/9/issues/12/notes'),
      hasLength(1),
    );
  });

  test('issueLinksProvider link refreshes, unlink removes in place', () async {
    adapter
      ..get('/projects/9/issues/12/links', fixtureJson('issue_links'))
      ..post(
        '/projects/9/issues/12/links',
        (fixtureJson('issue_links') as List).first,
      )
      ..get('/projects/9/issues/12/links', fixtureJson('issue_links'))
      ..delete('/projects/9/issues/12/links/100');

    const loc = (project: 9, iid: 12);
    final links = await container.read(issueLinksProvider(loc).future);
    expect(links, hasLength(2));

    await container
        .read(issueLinksProvider(loc).notifier)
        .link(9, 5, 'relates_to');
    expect(
      adapter.requestsTo('POST', '/projects/9/issues/12/links'),
      hasLength(1),
    );

    await container.read(issueLinksProvider(loc).notifier).unlink(100);
    final remaining = container.read(issueLinksProvider(loc)).value;
    expect(remaining, hasLength(1));
    expect(
      adapter.requestsTo('DELETE', '/projects/9/issues/12/links/100'),
      hasLength(1),
    );
  });

  test('issueRelatedMrsProvider loads related merge requests', () async {
    adapter.get(
      '/projects/9/issues/12/related_merge_requests',
      fixtureJson('related_mrs'),
    );

    const loc = (project: 9, iid: 12);
    final mrs = await container.read(issueRelatedMrsProvider(loc).future);
    expect(mrs, hasLength(2));
  });

  test('issueParticipantsProvider loads participants', () async {
    adapter.get(
      '/projects/9/issues/12/participants',
      fixtureJson('participants'),
    );

    const loc = (project: 9, iid: 12);
    final users = await container.read(issueParticipantsProvider(loc).future);
    expect(users, hasLength(2));
    expect(users.last.username, 'max');
  });
}
