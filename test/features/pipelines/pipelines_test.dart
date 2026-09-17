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

    test('schedules parses cron, owner and last pipeline', () async {
      final (client, adapter) = testClient();
      adapter.get(
        '/projects/42/pipeline_schedules',
        fixtureJson('pipeline_schedules'),
      );
      final repo = PipelinesRepository(client);

      final page = await repo.schedules(42);

      final s = page.items.first;
      expect(s.cron, '0 2 * * *');
      expect(s.cronTimezone, 'UTC');
      expect(s.active, isTrue);
      expect(s.owner?.username, 'jane');
      expect(s.lastPipelineStatus, 'success');
      expect(s.nextRunAt, isNotNull);
    });

    test('createSchedule posts the cron fields', () async {
      final (client, adapter) = testClient();
      adapter.post(
        '/projects/42/pipeline_schedules',
        (fixtureJson('pipeline_schedules') as List).first,
      );
      final repo = PipelinesRepository(client);

      final s = await repo.createSchedule(
        42,
        description: 'Nightly build',
        ref: 'main',
        cron: '0 2 * * *',
        cronTimezone: 'UTC',
      );

      expect(s.id, 31);
      final sent = adapter.lastRequest!.data as Map;
      expect(sent['cron'], '0 2 * * *');
      expect(sent['active'], true);
    });

    test('updateSchedule puts only the given fields', () async {
      final (client, adapter) = testClient();
      adapter.put(
        '/projects/42/pipeline_schedules/31',
        (fixtureJson('pipeline_schedules') as List).first,
      );
      final repo = PipelinesRepository(client);

      await repo.updateSchedule(42, 31, active: false);

      final sent = adapter.lastRequest!.data as Map;
      expect(sent['active'], false);
      expect(sent.containsKey('cron'), isFalse);
    });

    test('schedule variables use the sub-resource paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/pipeline_schedules/31/variables', {})
        ..put('/projects/42/pipeline_schedules/31/variables/NIGHTLY', {})
        ..delete('/projects/42/pipeline_schedules/31/variables/OLD_KEY');
      final repo = PipelinesRepository(client);

      await repo.createScheduleVariable(42, 31, key: 'NEW', value: 'x');
      await repo.updateScheduleVariable(42, 31, 'NIGHTLY', value: 'false');
      await repo.deleteScheduleVariable(42, 31, 'OLD_KEY');

      expect(
        adapter.requestsTo(
          'PUT',
          '/projects/42/pipeline_schedules/31/variables/NIGHTLY',
        ),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/pipeline_schedules/31/variables/OLD_KEY',
        ),
        hasLength(1),
      );
      final sent = adapter.requests.first.data as Map;
      expect(sent['variable_type'], 'env_var');
    });

    test('projectJobs forwards the scope filter', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/jobs', fixtureJson('jobs'));
      final repo = PipelinesRepository(client);

      final page = await repo.projectJobs(42, scope: 'running');

      expect(page.items, hasLength(3));
      final req = adapter.requestsTo('GET', '/projects/42/jobs').single;
      expect(req.queryParameters['scope'], 'running');
    });

    test('erase, keepArtifacts and deleteArtifacts hit their paths', () async {
      final (client, adapter) = testClient();
      final body = (fixtureJson('jobs') as List).first;
      adapter
        ..post('/projects/42/jobs/5001/erase', body)
        ..post('/projects/42/jobs/5001/artifacts/keep', body)
        ..delete('/projects/42/jobs/5001/artifacts');
      final repo = PipelinesRepository(client);

      await repo.eraseJob(42, 5001);
      await repo.keepArtifacts(42, 5001);
      await repo.deleteArtifacts(42, 5001);

      expect(
        adapter.requestsTo('POST', '/projects/42/jobs/5001/erase'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/jobs/5001/artifacts/keep'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('DELETE', '/projects/42/jobs/5001/artifacts'),
        hasLength(1),
      );
    });

    test('createTrigger posts the description and returns the token', () async {
      final (client, adapter) = testClient();
      final body =
          (fixtureJson('triggers') as List).first as Map<String, dynamic>;
      adapter.post('/projects/42/triggers', {
        ...body,
        'token': 'full-secret-token',
      });
      final repo = PipelinesRepository(client);

      final t = await repo.createTrigger(42, 'Deploy webhook');

      expect(t.token, 'full-secret-token');
      expect(t.id, 10);
      final sent = adapter.requestsTo('POST', '/projects/42/triggers').single;
      expect((sent.data as Map)['description'], 'Deploy webhook');
    });

    test('deleteTrigger hits the trigger path', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/42/triggers/10');
      final repo = PipelinesRepository(client);

      await repo.deleteTrigger(42, 10);

      expect(
        adapter.requestsTo('DELETE', '/projects/42/triggers/10'),
        hasLength(1),
      );
    });

    test('ciLint posts content and decodes errors', () async {
      final (client, adapter) = testClient();
      adapter.post('/projects/42/ci/lint', {
        'valid': false,
        'status': 'invalid',
        'errors': ['jobs:test config missing script'],
        'warnings': ['deprecated keyword'],
        'jobs': [
          {'name': 'build'},
          {'name': 'test'},
        ],
      });
      final repo = PipelinesRepository(client);

      final result = await repo.ciLint(42, 'test:\n  script: echo hi');

      expect(result.valid, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.warnings, hasLength(1));
      expect(result.jobs, ['build', 'test']);
      final sent = adapter.requestsTo('POST', '/projects/42/ci/lint').single;
      expect((sent.data as Map)['content'], contains('script'));
      expect((sent.data as Map)['include_jobs'], isTrue);
    });

    test('ciLint falls back to status when valid is absent', () async {
      final (client, adapter) = testClient();
      adapter.post('/projects/42/ci/lint', {
        'status': 'valid',
        'errors': <String>[],
        'warnings': <String>[],
      });
      final repo = PipelinesRepository(client);

      final result = await repo.ciLint(42, 'x');

      expect(result.valid, isTrue);
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

    test('pipelineSchedulesProvider plays and removes', () async {
      adapter
        ..get(
          '/projects/42/pipeline_schedules',
          fixtureJson('pipeline_schedules'),
        )
        ..post('/projects/42/pipeline_schedules/31/play', {
          'id': 901,
          'status': 'created',
        })
        ..get(
          '/projects/42/pipeline_schedules',
          fixtureJson('pipeline_schedules'),
        )
        ..delete('/projects/42/pipeline_schedules/32');

      final state = await container.read(pipelineSchedulesProvider(42).future);
      expect(state.items, hasLength(2));

      await container.read(pipelineSchedulesProvider(42).notifier).play(31);
      expect(
        adapter.requestsTo('POST', '/projects/42/pipeline_schedules/31/play'),
        hasLength(1),
      );

      await container.read(pipelineSchedulesProvider(42).notifier).remove(32);
      final items = container.read(pipelineSchedulesProvider(42)).value!.items;
      expect(items.single.id, 31);
    });

    test('scheduleDetailProvider loads variables', () async {
      adapter.get(
        '/projects/42/pipeline_schedules/31',
        fixtureJson('pipeline_schedule'),
      );

      const loc = (project: 42, id: 31);
      final s = await container.read(scheduleDetailProvider(loc).future);

      expect(s.variables, hasLength(2));
      expect(s.variables.first.key, 'NIGHTLY');
    });

    test('projectJobsProvider loads jobs and forwards scope', () async {
      adapter.get('/projects/42/jobs', fixtureJson('jobs'));

      const loc = (project: 42, scope: 'failed');
      final state = await container.read(projectJobsProvider(loc).future);

      expect(state.items, hasLength(3));
      final req = adapter.requestsTo('GET', '/projects/42/jobs').single;
      expect(req.queryParameters['scope'], 'failed');
    });

    test('pipelineTriggersProvider lists triggers', () async {
      adapter.get('/projects/42/triggers', fixtureJson('triggers'));

      final list = await container.read(pipelineTriggersProvider(42).future);

      expect(list, hasLength(2));
      expect(list.first.description, 'Deploy webhook');
      expect(list.first.owner, 'Jane Doe');
      expect(list.last.lastUsedAt, isNull);
    });
  });
}
