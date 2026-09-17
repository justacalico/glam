import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/labels/data/labels_repository.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';
import 'package:glam/src/features/milestones/data/milestones_repository.dart';
import 'package:glam/src/core/models/milestone.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Milestone', () {
    test('parses dates and state', () {
      final m = Milestone.fromJson(
        (fixtureJson('milestones') as List).first as Map<String, dynamic>,
      );
      expect(m.title, 'v1.0');
      expect(m.isActive, isTrue);
      expect(m.dueDate?.year, 2024);
    });
  });

  group('Label', () {
    test('parses counts and colors', () {
      final l = Label.fromJson(
        (fixtureJson('labels') as List).first as Map<String, dynamic>,
      );
      expect(l.color, '#d9534f');
      expect(l.openIssuesCount, 3);
    });
  });

  group('MilestonesRepository', () {
    test('project and group paths differ', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/milestones', fixtureJson('milestones'))
        ..get('/groups/9/milestones', fixtureJson('milestones'));
      final repo = MilestonesRepository(client);

      await repo.milestones(42, isProject: true, state: 'active');
      expect(adapter.lastRequest!.path, '/projects/42/milestones');
      expect(adapter.lastRequest!.queryParameters['state'], 'active');

      await repo.milestones(9, isProject: false);
      expect(adapter.lastRequest!.path, '/groups/9/milestones');
    });

    test('milestone detail, issues, and MRs', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/milestones/3',
          (fixtureJson('milestones') as List).first,
        )
        ..get('/projects/42/milestones/3/issues', fixtureJson('issues'))
        ..get('/projects/42/milestones/3/merge_requests', fixtureJson('mrs'));
      final repo = MilestonesRepository(client);

      final m = await repo.milestone(42, 3, isProject: true);
      final issues = await repo.milestoneIssues(42, 3);
      final mrs = await repo.milestoneMrs(42, 3);

      expect(m.iid, 3);
      expect(issues, isNotEmpty);
      expect(mrs, isNotEmpty);
    });

    test('create sends due_date', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/milestones',
        (fixtureJson('milestones') as List).first,
      );
      final repo = MilestonesRepository(client);

      final m = await repo.create(
        42,
        isProject: true,
        title: 'v1.0',
        dueDate: '2024-09-01',
      );

      expect(m.title, 'v1.0');
      final body =
          adapter.requestsTo('POST', '/projects/42/milestones').single.data
              as Map;
      expect(body['due_date'], '2024-09-01');
    });
  });

  group('LabelsRepository', () {
    test('list/create/update/delete', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/labels', fixtureJson('labels'))
        ..post('/projects/42/labels', (fixtureJson('labels') as List).first)
        ..put('/projects/42/labels', (fixtureJson('labels') as List).first)
        ..delete('/projects/42/labels');
      final repo = LabelsRepository(client);

      final labels = await repo.labels(42, isProject: true);
      final created = await repo.create(
        42,
        isProject: true,
        name: 'bug',
        color: '#d9534f',
      );
      await repo.update(42, isProject: true, name: 'bug', newName: 'critical');
      await repo.delete(42, isProject: true, name: 'bug');

      expect(labels, hasLength(2));
      expect(created.name, 'bug');
      final put = adapter.requestsTo('PUT', '/projects/42/labels').single;
      expect((put.data as Map)['new_name'], 'critical');
      final del = adapter.requestsTo('DELETE', '/projects/42/labels').single;
      expect(del.queryParameters['name'], 'bug');
    });

    test('subscribe, unsubscribe, and promote', () async {
      final (client, adapter) = testClient();
      final label = (fixtureJson('labels') as List).first;
      adapter
        ..post('/projects/42/labels/3/subscribe', label)
        ..delete('/projects/42/labels/3/subscribe')
        ..put('/projects/42/labels/3/promote', label);
      final repo = LabelsRepository(client);

      await repo.setSubscribed(
        42,
        isProject: true,
        labelId: 3,
        subscribed: true,
      );
      await repo.setSubscribed(
        42,
        isProject: true,
        labelId: 3,
        subscribed: false,
      );
      await repo.promote(42, 3);

      expect(
        adapter.requestsTo('POST', '/projects/42/labels/3/subscribe'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('DELETE', '/projects/42/labels/3/subscribe'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('PUT', '/projects/42/labels/3/promote'),
        hasLength(1),
      );
    });
  });

  group('providers', () {
    test('milestonesProvider filters by container kind', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/milestones', fixtureJson('milestones'))
        ..get('/groups/9/milestones', const []);
      final container = ProviderContainer(
        overrides: [
          milestonesRepositoryProvider.overrideWithValue(
            MilestonesRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      final proj = await container.read(
        milestonesProvider((
          scope: (id: 42, isProject: true),
          state: null,
          search: null,
        )).future,
      );
      final group = await container.read(
        milestonesProvider((
          scope: (id: 9, isProject: false),
          state: null,
          search: null,
        )).future,
      );

      expect(proj.items, hasLength(2));
      expect(group.items, isEmpty);
    });

    test('milestonesProvider forwards the search filter', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/milestones', fixtureJson('milestones'));
      final container = ProviderContainer(
        overrides: [
          milestonesRepositoryProvider.overrideWithValue(
            MilestonesRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(
        milestonesProvider((
          scope: (id: 42, isProject: true),
          state: null,
          search: 'sprint',
        )).future,
      );

      expect(adapter.lastRequest!.queryParameters['search'], 'sprint');
    });
  });
}
