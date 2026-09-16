import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('list', () {
    test('decodes projects and sends filter params', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects', fixtureList('project'));
      final repo = ProjectsRepository(client);

      final page = await repo.list(
        filter: const ProjectFilter(
          scope: ProjectScope.starred,
          search: 'glam',
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.items.first.name, 'Glam');
      final params = adapter.lastRequest!.queryParameters;
      expect(params['starred'], true);
      expect(params['search'], 'glam');
    });
  });

  test('get decodes a single project', () async {
    final (client, adapter) = testClient();
    adapter.get('/projects/42', fixtureJson('project'));

    final project = await ProjectsRepository(client).get(42);

    expect(project.id, 42);
    expect(project.pathWithNamespace, 'calico/glam');
    expect(project.owner?.username, 'calico');
    expect(project.topics, ['flutter', 'gitlab']);
  });

  test('get url-encodes string paths', () async {
    final (client, adapter) = testClient();
    adapter.get('/projects/group%2Fsub', fixtureJson('project'));

    await ProjectsRepository(client).get('group/sub');

    expect(adapter.lastRequest!.path, '/projects/group%2Fsub');
  });

  test('star/unstar post to the right endpoints', () async {
    final (client, adapter) = testClient();
    adapter.post('/projects/42/star', fixtureJson('project'));
    adapter.post('/projects/42/unstar', fixtureJson('project'));
    final repo = ProjectsRepository(client);

    await repo.star(42);
    await repo.unstar(42);

    expect(adapter.requestsTo('POST', '/projects/42/star'), hasLength(1));
    expect(adapter.requestsTo('POST', '/projects/42/unstar'), hasLength(1));
  });

  test('fork posts to the fork endpoint', () async {
    final (client, adapter) = testClient();
    adapter.post('/projects/42/fork', fixtureJson('project'));

    await ProjectsRepository(client).fork(42);

    expect(adapter.requestsTo('POST', '/projects/42/fork'), hasLength(1));
  });
}
