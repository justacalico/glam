import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/wiki/application/wiki_providers.dart';
import 'package:glam/src/features/wiki/data/wiki_repository.dart';
import 'package:glam/src/features/wiki/domain/wiki_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  test('WikiPage parses list and full shapes', () {
    final list = (fixtureJson('wiki_pages') as List)
        .cast<Map<String, dynamic>>()
        .map(WikiPage.fromJson)
        .toList();
    expect(list.first.slug, 'home');
    expect(list.first.content, isNull);

    final full = WikiPage.fromJson(
      fixtureJson('wiki_page') as Map<String, dynamic>,
    );
    expect(full.content, contains('# Welcome'));
  });

  test('repository hits the right endpoints', () async {
    final (client, adapter) = testClient();
    adapter
      ..get('/projects/42/wikis', fixtureJson('wiki_pages'))
      ..get('/projects/42/wikis/home', fixtureJson('wiki_page'))
      ..post('/projects/42/wikis', fixtureJson('wiki_page'))
      ..put('/projects/42/wikis/home', fixtureJson('wiki_page'))
      ..delete('/projects/42/wikis/home');
    final repo = WikiRepository(client);

    final pages = await repo.pages(42);
    final page = await repo.page(42, 'home');
    await repo.create(42, title: 'Home', content: '# hi');
    await repo.update(42, 'home', content: 'new');
    await repo.delete(42, 'home');

    expect(pages.items, hasLength(2));
    expect(page.content, contains('Welcome'));
    final post = adapter.requestsTo('POST', '/projects/42/wikis').single;
    expect((post.data as Map)['title'], 'Home');
    expect(
      adapter.requestsTo('DELETE', '/projects/42/wikis/home'),
      hasLength(1),
    );
  });

  test('uploadAttachment posts multipart and returns markdown', () async {
    final (client, adapter) = testClient();
    adapter.post('/projects/42/wikis/attachments', {
      'file_name': 'img.png',
      'markdown': '![img](uploads/abc/img.png)',
    });
    final repo = WikiRepository(client);

    final md = await repo.uploadAttachment(
      42,
      Uint8List.fromList([1, 2, 3]),
      'img.png',
    );

    expect(md, '![img](uploads/abc/img.png)');
    expect(
      adapter.requestsTo('POST', '/projects/42/wikis/attachments'),
      hasLength(1),
    );
    expect(adapter.lastRequest!.data, isA<FormData>());
  });

  test('wikiPagesProvider loads pages', () async {
    final (client, adapter) = testClient();
    adapter.get('/projects/42/wikis', fixtureJson('wiki_pages'));
    final container = ProviderContainer(
      overrides: [
        wikiRepositoryProvider.overrideWithValue(WikiRepository(client)),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(wikiPagesProvider(42).future);
    expect(state.items, hasLength(2));
  });
}
