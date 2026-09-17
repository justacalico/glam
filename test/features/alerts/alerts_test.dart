import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/alerts/application/alerts_providers.dart';
import 'package:glam/src/features/alerts/data/alerts_repository.dart';
import 'package:glam/src/features/alerts/domain/alert.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Alert model', () {
    test('parses status, severity, and hosts', () {
      final alert = Alert.fromJson(
        (fixtureJson('alerts') as List).first as Map<String, dynamic>,
      );
      expect(alert.iid, 1);
      expect(alert.status, 'triggered');
      expect(alert.severity, 'critical');
      expect(alert.monitoringTool, 'prometheus');
      expect(alert.eventCount, 12);
      expect(alert.hosts, ['web-1', 'web-2']);
      expect(alert.issueIid, 14);
      expect(alert.assignees.single.username, 'lin');
    });
  });

  group('alerts repository', () {
    test('lists alerts with the status filter', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/alert_management/alerts',
        fixtureJson('alerts'),
      );
      final repo = AlertsRepository(client);

      final page = await repo.alerts(42, status: 'triggered');

      expect(page.items, hasLength(2));
      expect(adapter.lastRequest!.queryParameters['status'], 'triggered');
    });

    test('updateAlert puts the status', () async {
      final (client, adapter) = testClient();
      final updated =
          (fixtureJson('alerts') as List).first as Map<String, dynamic>;
      adapter.put('/projects/42/alert_management/alerts/1', updated);
      final repo = AlertsRepository(client);

      await repo.updateAlert(42, 1, status: 'acknowledged');

      expect(
        (adapter.lastRequest!.data as Map)['status'],
        'acknowledged',
      );
    });
  });

  group('alerts providers', () {
    test('projectAlertsProvider loads and updates status', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/alert_management/alerts', fixtureJson('alerts'))
        ..put(
          '/projects/42/alert_management/alerts/1',
          (fixtureJson('alerts') as List).last,
        );
      final container = ProviderContainer(
        overrides: [
          alertsRepositoryProvider.overrideWithValue(
            AlertsRepository(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      const filter = (project: 42, status: null);
      final state = await container.read(
        projectAlertsProvider(filter).future,
      );
      expect(state.items, hasLength(2));

      await container
          .read(projectAlertsProvider(filter).notifier)
          .setStatus(1, 'acknowledged');

      final items = container
          .read(projectAlertsProvider(filter))
          .value!
          .items;
      expect(items.first.title, 'Disk space low');
    });
  });
}
