import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/data/groups_repository.dart';
import 'package:glam/src/features/groups/domain/group.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Group model', () {
    test('parses paths and statistics', () {
      final g = Group.fromJson(
        (fixtureJson('groups') as List).first as Map<String, dynamic>,
      );
      expect(g.fullPath, 'calico');
      expect(g.projectCount, 4);
      expect(g.subgroupCount, 1);
    });
  });

  group('Member model', () {
    test('maps access levels to labels', () {
      final members = (fixtureJson('members') as List)
          .cast<Map<String, dynamic>>()
          .map(Member.fromJson)
          .toList();
      expect(members[0].roleLabel, 'Owner');
      expect(members[1].roleLabel, 'Developer');
      expect(members[1].expiresAt, isNotNull);
    });
  });

  group('GroupsRepository', () {
    test('lists top-level groups with search', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups', fixtureJson('groups'));
      final repo = GroupsRepository(client);

      final page = await repo.groups(search: 'cal');

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['search'], 'cal');
      expect(query['top_level_only'], true);
    });

    test('groupProjects scopes to direct children', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/projects', [fixtureJson('project')]);
      final repo = GroupsRepository(client);

      final page = await repo.groupProjects(9);

      expect(page.items.single.name, 'Glam');
      expect(adapter.lastRequest!.queryParameters['include_subgroups'], false);
    });

    test('subgroups hits the subgroups path', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/subgroups', fixtureJson('groups'));
      final repo = GroupsRepository(client);

      final page = await repo.subgroups(9);

      expect(page.items, hasLength(2));
    });

    test('iterations lists open group iterations', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/iterations', fixtureJson('iterations'));
      final repo = GroupsRepository(client);

      final items = await repo.iterations(9);

      expect(items, hasLength(2));
      expect(items.first.title, 'Sprint 12');
      // `state` arrives as an int enum: 2 = current, 1 = upcoming.
      expect(items.first.state, 'current');
      expect(items.last.state, 'upcoming');
      // Untitled iterations fall back to the date range.
      expect(items.last.title, isNull);
      expect(items.last.label, contains('Apr 28'));
      expect(items.first.dueDate, isNotNull);
      expect(adapter.lastRequest!.queryParameters['state'], 'opened');
    });

    test('members work for groups and projects', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/groups/9/members/all', fixtureJson('members'))
        ..get('/projects/42/members/all', fixtureJson('members'));
      final repo = GroupsRepository(client);

      final gm = await repo.groupMembers(9);
      final pm = await repo.projectMembers(42);

      expect(gm.items, hasLength(2));
      expect(pm.items.first.roleLabel, 'Owner');
    });

    test('member management posts to /members', () async {
      final (client, adapter) = testClient();
      final member = (fixtureJson('members') as List).first;
      adapter
        ..post('/projects/42/members', member)
        ..put('/projects/42/members/7', member)
        ..delete('/projects/42/members/7');
      final repo = GroupsRepository(client);

      final added = await repo.addMember(
        42,
        isProject: true,
        username: 'jane',
        accessLevel: 30,
        expiresAt: '2026-01-01',
      );
      await repo.updateMember(42, 7, isProject: true, accessLevel: 40);
      await repo.removeMember(42, 7, isProject: true);

      expect(added.username, 'jane');
      final post = adapter.requestsTo('POST', '/projects/42/members').single;
      final body = post.data as Map;
      expect(body['username'], 'jane');
      expect(body['access_level'], 30);
      final put = adapter.requestsTo('PUT', '/projects/42/members/7').single;
      expect((put.data as Map)['access_level'], 40);
      expect(
        adapter.requestsTo('DELETE', '/projects/42/members/7'),
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
      a
        ..get('/groups', fixtureJson('groups'))
        ..get('/groups/9', (fixtureJson('groups') as List).first);
      container = ProviderContainer(
        overrides: [
          groupsRepositoryProvider.overrideWithValue(GroupsRepository(client)),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('groupsProvider loads groups', () async {
      final state = await container.read(groupsProvider(null).future);
      expect(state.items, hasLength(2));
    });

    test('groupProvider loads one group', () async {
      final g = await container.read(groupProvider(9).future);
      expect(g.name, 'calico');
    });

    test('groupIterationsProvider lists every state', () async {
      adapter.get('/groups/9/iterations', fixtureJson('iterations'));

      final items = await container.read(groupIterationsProvider(9).future);

      expect(items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['state'], 'all');
    });

    test(
      'groupIterationsProvider is empty when the route is missing',
      () async {
        adapter.fail('/groups/9/iterations', status: 404);

        final items = await container.read(groupIterationsProvider(9).future);
        expect(items, isEmpty);
      },
    );

    test('groupIterationsProvider encodes nested group paths', () async {
      adapter.get('/groups/a%2Fb/iterations', fixtureJson('iterations'));

      final items = await container.read(groupIterationsProvider('a/b').future);
      expect(items, hasLength(2));
    });
  });
}
