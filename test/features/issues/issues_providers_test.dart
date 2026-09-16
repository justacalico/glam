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
    ));
    await container.read(issuesProvider.future);

    final query = adapter.lastRequest!.queryParameters;
    expect(query['scope'], 'all');
    expect(query['search'], 'x');
  });

  test('projectIssuesProvider is scoped per filter', () async {
    adapter.get('/projects/9/issues', fixtureJson('issues'));

    const filter = (project: 9, state: 'opened', search: null);
    final state = await container.read(projectIssuesProvider(filter).future);

    expect(state.items, hasLength(2));
    expect(adapter.lastRequest!.queryParameters['state'], 'opened');
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
}
