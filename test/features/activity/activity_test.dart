import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/activity/application/activity_providers.dart';
import 'package:glam/src/features/activity/data/activity_repository.dart';
import 'package:glam/src/features/activity/domain/event.dart';
import 'package:glam/src/features/activity/domain/notification.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('ActivityEvent', () {
    late List<ActivityEvent> events;

    setUp(() {
      events = (fixtureJson('events') as List)
          .cast<Map<String, dynamic>>()
          .map(ActivityEvent.fromJson)
          .toList();
    });

    test('parses push data and notes', () {
      expect(events[0].pushData?.ref, 'main');
      expect(events[0].pushData?.commitCount, 3);
      expect(events[1].note, 'LGTM with a nit');
    });

    test('describe produces a readable line', () {
      expect(events[0].describe(), contains('Jane Doe'));
      expect(events[0].describe(), contains('main'));
      expect(events[1].describe(), contains('!9'));
    });

    test('routes point at issue and MR detail', () {
      expect(events[2].route, '/projects/42/issues/5');
      expect(events[1].route, '/projects/42/mrs/9');
      expect(events[0].route, isNull);
    });
  });

  group('GlamNotification', () {
    test('parses reason, target, and routes', () {
      final list = (fixtureJson('notifications') as List)
          .cast<Map<String, dynamic>>()
          .map(GlamNotification.fromJson)
          .toList();
      expect(list[0].reasonLabel, 'Mentioned you');
      expect(list[0].route, '/projects/42/mrs/9');
      expect(list[1].route, '/projects/42/issues/5');
    });
  });

  group('ActivityRepository', () {
    test('events, projectEvents, userEvents hit their paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/events', fixtureJson('events'))
        ..get('/projects/42/events', fixtureJson('events'))
        ..get('/users/7/events', fixtureJson('events'));
      final repo = ActivityRepository(client);

      await repo.events(action: 'pushed to');
      expect(adapter.lastRequest!.queryParameters['action'], 'pushed to');

      await repo.projectEvents(42);
      expect(adapter.lastRequest!.path, '/projects/42/events');

      await repo.userEvents(7);
      expect(adapter.lastRequest!.path, '/users/7/events');
    });

    test('notifications + markAllRead', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/notifications', fixtureJson('notifications'))
        ..post('/notifications/mark_as_read', const {});
      final repo = ActivityRepository(client);

      final page = await repo.notifications();
      await repo.markAllRead();

      expect(page.items, hasLength(2));
      expect(
        adapter.requestsTo('POST', '/notifications/mark_as_read'),
        hasLength(1),
      );
    });
  });

  group('providers', () {
    test('activity feed dispatches on kind', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/events', fixtureJson('events'))
        ..get('/projects/42/events', fixtureJson('events'));
      final container = ProviderContainer(
        overrides: [
          activityRepositoryProvider.overrideWithValue(
            ActivityRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      final own = await container.read(activityProvider(ownFeed).future);
      final proj = await container.read(
        activityProvider((kind: 'project', id: 42)).future,
      );

      expect(own.items, hasLength(3));
      expect(proj.items, hasLength(3));
    });

    test('notificationsProvider loads', () async {
      final (client, adapter) = testClient();
      adapter.get('/notifications', fixtureJson('notifications'));
      final container = ProviderContainer(
        overrides: [
          activityRepositoryProvider.overrideWithValue(
            ActivityRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(notificationsProvider.future);
      expect(state.items, hasLength(2));
    });
  });
}
