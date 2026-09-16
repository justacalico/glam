import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';

import '../../helpers/test_client.dart';

void main() {
  group('normalizeInstanceUrl', () {
    test('defaults bare domains to https', () {
      expect(
        GitLabApiClient.normalizeInstanceUrl('gitlab.example.com'),
        'https://gitlab.example.com',
      );
    });

    test('strips trailing slashes', () {
      expect(
        GitLabApiClient.normalizeInstanceUrl('https://gitlab.com/'),
        'https://gitlab.com',
      );
    });

    test('strips an /api/v4 suffix', () {
      expect(
        GitLabApiClient.normalizeInstanceUrl('https://gitlab.com/api/v4'),
        'https://gitlab.com',
      );
    });

    test('empty input falls back to gitlab.com', () {
      expect(GitLabApiClient.normalizeInstanceUrl('   '), 'https://gitlab.com');
    });
  });

  group('requests', () {
    test('sends the token as PRIVATE-TOKEN header', () async {
      final (client, adapter) = testClient(token: 'secret-token');
      adapter.get('/user', {'id': 1});

      await client.get('/user', decoder: (j) => j);

      expect(adapter.lastRequest!.headers['PRIVATE-TOKEN'], 'secret-token');
    });

    test('get decodes json through the provided decoder', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42', {'id': 42, 'name': 'Glam'});

      final name = await client.get<String>(
        '/projects/42',
        decoder: (j) => (j! as Map)['name'] as String,
      );
      expect(name, 'Glam');
    });

    test('get strips null query parameters', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects', []);

      await client.getList(
        '/projects',
        query: {'search': 'glam', 'state': null},
        decoder: (j) => j,
      );

      expect(adapter.lastRequest!.queryParameters, {'search': 'glam'});
    });

    test('getList returns empty list for non-list bodies', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects', {'oops': true});

      final list = await client.getList('/projects', decoder: (j) => j);
      expect(list, isEmpty);
    });

    test('getPage reads pagination headers', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects',
        [
          {'id': 1},
        ],
        headers: {
          'x-next-page': ['2'],
          'x-total': ['21'],
          'x-page': ['1'],
        },
      );

      final page = await client.getPage(
        '/projects',
        page: 1,
        perPage: 20,
        decoder: (j) => (j! as Map)['id'] as int,
      );

      expect(page.items, [1]);
      expect(page.hasMore, isTrue);
      expect(page.nextPage, 2);
      expect(page.total, 21);
    });

    test('getPage sends page params', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects', []);

      await client.getPage(
        '/projects',
        page: 3,
        perPage: 50,
        decoder: (j) => j,
      );

      expect(adapter.lastRequest!.queryParameters['page'], 3);
      expect(adapter.lastRequest!.queryParameters['per_page'], 50);
    });

    test('getAll walks pages until x-next-page is gone', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/labels',
        [
          {'id': 1},
        ],
        headers: {
          'x-next-page': ['2'],
        },
      );
      adapter.get('/labels', [
        {'id': 2},
        {'id': 3},
      ]);

      final items = await client.getAll(
        '/labels',
        decoder: (j) => (j! as Map)['id'],
      );

      expect(items, [1, 2, 3]);
    });

    test('post sends the body', () async {
      final (client, adapter) = testClient();
      adapter.post('/projects/1/star', {'id': 1});

      await client.post('/projects/1/star', body: {'x': 1}, decoder: (j) => j);

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.data, {'x': 1});
    });

    test('put sends the body', () async {
      final (client, adapter) = testClient();
      adapter.put('/projects/1', {'id': 1});

      await client.put('/projects/1', body: {'name': 'x'}, decoder: (j) => j);
      expect(adapter.lastRequest!.method, 'PUT');
    });

    test('delete returns null without a decoder', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/1');

      final result = await client.delete<Object?>('/projects/1');
      expect(result, isNull);
      expect(adapter.lastRequest!.method, 'DELETE');
    });

    test('getRaw returns plain text', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/1/jobs/2/trace', 'log line');

      final trace = await client.getRaw('/projects/1/jobs/2/trace');
      expect(trace, 'log line');
    });

    test('encodeProject url-encodes namespaced paths', () {
      expect(
        GitLabApiClient.encodeProject('group/sub/project'),
        'group%2Fsub%2Fproject',
      );
      expect(GitLabApiClient.encodeProject(42), '42');
    });
  });

  group('errors', () {
    test('maps 401 to unauthorized', () async {
      final (client, adapter) = testClient();
      adapter.fail('/user', status: 401, body: {'message': 'bad token'});

      await expectLater(
        client.get('/user', decoder: (j) => j),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)
              .having((e) => e.message, 'message', 'bad token'),
        ),
      );
    });

    test('maps 404 to notFound', () async {
      final (client, adapter) = testClient();
      adapter.fail('/nope', status: 404);

      await expectLater(
        client.get('/nope', decoder: (j) => j),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.notFound,
          ),
        ),
      );
    });

    test('unstubbed routes surface as ApiException', () async {
      final (client, _) = testClient();
      await expectLater(
        client.get('/unstubbed', decoder: (j) => j),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
