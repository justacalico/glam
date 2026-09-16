import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/data/pipelines_repository.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('Pipeline model', () {
    test('parses status, ref, sha, duration', () {
      final p = Pipeline.fromJson(
        (fixtureJson('pipelines') as List).first as Map<String, dynamic>,
      );
      expect(p.id, 900);
      expect(p.status, 'success');
      expect(p.ref, 'main');
      expect(p.duration, 692.5);
      expect(p.isRunning, isFalse);
      expect(p.user?.name, 'Jane Doe');
    });

    test('running/pending count as running', () {
      final running = Pipeline.fromJson(
        (fixtureJson('pipelines') as List).last as Map<String, dynamic>,
      );
      expect(running.isRunning, isTrue);
      expect(running.status, 'running');
    });
  });

  group('Job model', () {
    test('parses stage, tags, allow_failure', () {
      final j = Job.fromJson(
        (fixtureJson('jobs') as List).first as Map<String, dynamic>,
      );
      expect(j.name, 'lint');
      expect(j.stage, 'test');
      expect(j.tagList, ['flutter', 'docker']);
      expect(j.allowFailure, isFalse);
    });
  });

  group('PipelinesRepository', () {
    test('lists pipelines newest first', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/pipelines', fixtureJson('pipelines'));
      final repo = PipelinesRepository(client);

      final page = await repo.pipelines(42);

      expect(page.items, hasLength(2));
      final query = adapter.lastRequest!.queryParameters;
      expect(query['order_by'], 'id');
      expect(query['sort'], 'desc');
    });

    test('ref and status filters are forwarded', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/pipelines', const []);
      final repo = PipelinesRepository(client);

      await repo.pipelines(42, ref: 'main', status: 'failed');

      final query = adapter.lastRequest!.queryParameters;
      expect(query['ref'], 'main');
      expect(query['status'], 'failed');
    });

    test('retry and cancel post to the right paths', () async {
      final (client, adapter) = testClient();
      final body = (fixtureJson('pipelines') as List).first;
      adapter
        ..post('/projects/42/pipelines/900/retry', body)
        ..post('/projects/42/pipelines/900/cancel', body);
      final repo = PipelinesRepository(client);

      await repo.retryPipeline(42, 900);
      await repo.cancelPipeline(42, 900);

      expect(
        adapter.requestsTo('POST', '/projects/42/pipelines/900/retry'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/pipelines/900/cancel'),
        hasLength(1),
      );
    });

    test('createPipeline posts the ref', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/pipeline',
        (fixtureJson('pipelines') as List).first,
      );
      final repo = PipelinesRepository(client);

      await repo.createPipeline(42, 'main');

      expect((adapter.lastRequest!.data as Map)['ref'], 'main');
    });

    test('jobs list decodes jobs', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/pipelines/900/jobs', fixtureJson('jobs'));
      final repo = PipelinesRepository(client);

      final page = await repo.jobs(42, 900);

      expect(page.items, hasLength(3));
      expect(page.items[1].status, 'failed');
      expect(page.items[2].status, 'manual');
    });

    test('jobTrace returns raw text', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/jobs/5001/trace', 'line1\nline2');
      final repo = PipelinesRepository(client);

      final trace = await repo.jobTrace(42, 5001);

      expect(trace, 'line1\nline2');
    });

    test('job actions hit retry/cancel/play', () async {
      final (client, adapter) = testClient();
      final body = (fixtureJson('jobs') as List).first;
      adapter
        ..post('/projects/42/jobs/5001/retry', body)
        ..post('/projects/42/jobs/5001/cancel', body)
        ..post('/projects/42/jobs/5001/play', body);
      final repo = PipelinesRepository(client);

      await repo.retryJob(42, 5001);
      await repo.cancelJob(42, 5001);
      await repo.playJob(42, 5001);

      expect(
        adapter.requestsTo('POST', '/projects/42/jobs/5001/retry'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/jobs/5001/cancel'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/jobs/5001/play'),
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
      container = ProviderContainer(
        overrides: [
          pipelinesRepositoryProvider.overrideWithValue(
            PipelinesRepository(client),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('pipelinesProvider loads pages', () async {
      adapter.get('/projects/42/pipelines', fixtureJson('pipelines'));

      final state = await container.read(pipelinesProvider(42).future);

      expect(state.items, hasLength(2));
      expect(state.items.first.status, 'success');
    });

    test('pipelineJobsProvider loads jobs', () async {
      adapter.get('/projects/42/pipelines/900/jobs', fixtureJson('jobs'));

      const loc = (project: 42, id: 900);
      final state = await container.read(pipelineJobsProvider(loc).future);

      expect(state.items, hasLength(3));
    });

    test('jobTraceProvider returns the trace', () async {
      adapter.get('/projects/42/jobs/5001/trace', 'build output');

      const loc = (project: 42, id: 5001);
      final trace = await container.read(jobTraceProvider(loc).future);

      expect(trace, 'build output');
    });
  });
}
