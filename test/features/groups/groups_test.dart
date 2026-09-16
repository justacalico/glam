import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/groups/application/groups_providers.dart';
import 'package:glam/src/features/groups/data/groups_repository.dart';
import 'package:glam/src/features/groups/domain/group.dart';

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
  });

  group('providers', () {
    late ProviderContainer container;

    setUp(() {
      final (client, a) = testClient();
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
  });
}
