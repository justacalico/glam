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

    test('sharedProjects hits the shared path', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/projects/shared', [fixtureJson('project')]);
      final repo = GroupsRepository(client);

      final page = await repo.sharedProjects(9);

      expect(page.items.single.name, 'Glam');
      expect(
        adapter.requestsTo('GET', '/groups/9/projects/shared'),
        hasLength(1),
      );
    });

    test('group variables list and mutate', () async {
      final (client, adapter) = testClient();
      final variable = (fixtureJson('variables') as List).first;
      adapter
        ..get('/groups/9/variables', fixtureJson('variables'))
        ..post('/groups/9/variables', variable)
        ..put('/groups/9/variables/API_KEY', variable)
        ..delete('/groups/9/variables/API_KEY');
      final repo = GroupsRepository(client);

      final vars = await repo.groupVariables(9);
      expect(vars, isNotEmpty);

      await repo.createGroupVariable(
        9,
        key: 'API_KEY',
        value: 'secret',
        masked: true,
      );
      await repo.updateGroupVariable(9, 'API_KEY', value: 'v2');
      await repo.deleteGroupVariable(9, 'API_KEY');

      final post = adapter.requestsTo('POST', '/groups/9/variables').single;
      expect((post.data as Map)['masked'], isTrue);
      final put = adapter
          .requestsTo('PUT', '/groups/9/variables/API_KEY')
          .single;
      expect((put.data as Map)['value'], 'v2');
      expect(
        adapter.requestsTo('DELETE', '/groups/9/variables/API_KEY'),
        hasLength(1),
      );
    });

    test('group webhooks list, create, test, delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/groups/9/hooks', [
          {
            'id': 7,
            'url': 'https://example.com/hook',
            'push_events': true,
            'subgroup_events': true,
          },
        ])
        ..post('/groups/9/hooks', {'id': 8, 'url': 'https://x.test/h'})
        ..post('/groups/9/hooks/7/test/push_events', {})
        ..delete('/groups/9/hooks/7');
      final repo = GroupsRepository(client);

      final hooks = await repo.webhooks(9);
      expect(hooks.single.url, 'https://example.com/hook');
      expect(hooks.single.subgroupEvents, isTrue);

      await repo.createHook(
        9,
        url: 'https://x.test/h',
        events: {'subgroup_events': true},
        enableSslVerification: false,
      );
      final sent = adapter.requestsTo('POST', '/groups/9/hooks').single;
      final body = sent.data as Map;
      expect(body['subgroup_events'], isTrue);
      expect(body['enable_ssl_verification'], isFalse);

      await repo.testHook(9, 7);
      await repo.deleteHook(9, 7);
      expect(adapter.requestsTo('DELETE', '/groups/9/hooks/7'), hasLength(1));
    });

    test('auditEvents decodes detail fields', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9/audit_events', [
        {
          'id': 3,
          'entity_type': 'Group',
          'details': {
            'change': 'member added',
            'author_name': 'Administrator',
            'target_details': 'ada@x.test',
          },
          'created_at': '2024-06-01T10:00:00.000Z',
        },
      ]);
      final repo = GroupsRepository(client);

      final events = await repo.auditEvents(9);

      expect(events.single.authorName, 'Administrator');
      expect(events.single.change, 'member added');
      expect(events.single.entityType, 'Group');
    });

    test('access requests list, approve and deny', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/groups/9/access_requests', [
          {'id': 7, 'username': 'ada', 'name': 'Ada', 'access_level': 30},
        ])
        ..get('/projects/42/access_requests', [])
        ..put('/groups/9/access_requests/7/approve', {})
        ..delete('/groups/9/access_requests/7');
      final repo = GroupsRepository(client);

      final pending = await repo.accessRequests(9, isProject: false);
      expect(pending.single.username, 'ada');
      expect(pending.single.accessLevel, 30);

      await repo.approveAccessRequest(9, 7, isProject: false, accessLevel: 30);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['access_level'], 30);

      await repo.denyAccessRequest(9, 7, isProject: false);
      expect(
        adapter.requestsTo('DELETE', '/groups/9/access_requests/7'),
        hasLength(1),
      );

      await repo.accessRequests(42, isProject: true);
      expect(adapter.lastRequest!.path, '/projects/42/access_requests');
    });

    test('share and unshare group hit the share paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/groups/9/share', {})
        ..delete('/groups/9/share/4');
      final repo = GroupsRepository(client);

      await repo.shareGroup(
        9,
        groupId: 4,
        accessLevel: 30,
        expiresAt: DateTime(2025, 12, 31),
      );
      await repo.unshareGroup(9, 4);

      final sent = adapter.requestsTo('POST', '/groups/9/share').single;
      expect((sent.data as Map)['group_id'], 4);
      expect((sent.data as Map)['group_access'], 30);
      expect((sent.data as Map)['expires_at'], '2025-12-31');
      expect(adapter.requestsTo('DELETE', '/groups/9/share/4'), hasLength(1));
    });

    test('group decodes shared_with_groups', () async {
      final (client, adapter) = testClient();
      adapter.get('/groups/9', {
        'id': 9,
        'name': 'calico',
        'full_path': 'calico',
        'shared_with_groups': [
          {
            'group_id': 4,
            'group_name': 'Design',
            'group_full_path': 'design',
            'group_access_level': 30,
            'expires_at': '2025-12-31',
          },
        ],
      });
      final repo = GroupsRepository(client);

      final g = await repo.group(9);

      expect(g.sharedWithGroups.single.groupId, 4);
      expect(g.sharedWithGroups.single.roleLabel, 'Developer');
      expect(g.sharedWithGroups.single.expiresAt, isNotNull);
    });

    test('create and delete groups hit the /groups paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/groups', (fixtureJson('groups') as List).first)
        ..delete('/groups/9');
      final repo = GroupsRepository(client);

      final g = await repo.createGroup(
        name: 'Platform',
        path: 'platform',
        parentId: 9,
        visibility: 'private',
      );
      await repo.deleteGroup(9);

      expect(g.fullPath, 'calico');
      final sent = adapter.requestsTo('POST', '/groups').single;
      final body = sent.data as Map;
      expect(body['name'], 'Platform');
      expect(body['path'], 'platform');
      expect(body['parent_id'], 9);
      expect(body['visibility'], 'private');
      expect(adapter.requestsTo('DELETE', '/groups/9'), hasLength(1));
    });

    test('updateGroup puts name, path and visibility', () async {
      final (client, adapter) = testClient();
      adapter.put('/groups/9', (fixtureJson('groups') as List).first);
      final repo = GroupsRepository(client);

      await repo.updateGroup(
        9,
        name: 'Platform',
        path: 'platform',
        visibility: 'internal',
      );

      final sent = adapter.requestsTo('PUT', '/groups/9').single;
      final body = sent.data as Map;
      expect(body['name'], 'Platform');
      expect(body['path'], 'platform');
      expect(body['visibility'], 'internal');
      expect(body.containsKey('description'), isFalse);
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

    test('addMember sends email invites', () async {
      final (client, adapter) = testClient();
      adapter.post('/groups/9/members', (fixtureJson('members') as List).first);
      final repo = GroupsRepository(client);

      await repo.addMember(
        9,
        isProject: false,
        email: 'jane@example.com',
        accessLevel: 30,
      );

      final body =
          adapter.requestsTo('POST', '/groups/9/members').single.data as Map;
      expect(body['email'], 'jane@example.com');
      expect(body.containsKey('username'), isFalse);
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

    test('sharedProjectsProvider loads shared projects', () async {
      adapter.get('/groups/9/projects/shared', [fixtureJson('project')]);

      final state = await container.read(sharedProjectsProvider(9).future);
      expect(state.items.single.name, 'Glam');
    });

    test('groupVariablesProvider lists variables', () async {
      adapter.get('/groups/9/variables', fixtureJson('variables'));

      final vars = await container.read(groupVariablesProvider(9).future);
      expect(vars, isNotEmpty);
    });

    test('groupAuditEventsProvider loads events', () async {
      adapter.get('/groups/9/audit_events', [
        {
          'id': 3,
          'details': {'change': 'member added'},
        },
      ]);

      final events = await container.read(groupAuditEventsProvider(9).future);

      expect(events.single.change, 'member added');
    });

    test('groupAuditEventsProvider is empty when premium-gated', () async {
      adapter.fail('/groups/9/audit_events', status: 403);

      final events = await container.read(groupAuditEventsProvider(9).future);

      expect(events, isEmpty);
    });

    test('accessRequestsProvider lists pending requests', () async {
      adapter.get('/groups/9/access_requests', [
        {'id': 7, 'username': 'ada', 'name': 'Ada'},
      ]);

      final pending = await container.read(
        accessRequestsProvider((id: 9, isProject: false)).future,
      );

      expect(pending.single.name, 'Ada');
    });

    test('accessRequestsProvider is empty for non-maintainers', () async {
      adapter.fail('/groups/9/access_requests', status: 403);

      final pending = await container.read(
        accessRequestsProvider((id: 9, isProject: false)).future,
      );

      expect(pending, isEmpty);
    });
  });
}
