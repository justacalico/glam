import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  group('list', () {
    test('decodes projects and sends filter params', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects', fixtureList('project'));
      final repo = ProjectsRepository(client);

      final page = await repo.list(
        filter: const ProjectFilter(
          scope: ProjectScope.starred,
          search: 'glam',
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.items.first.name, 'Glam');
      final params = adapter.lastRequest!.queryParameters;
      expect(params['starred'], true);
      expect(params['search'], 'glam');
    });
  });

  test('get decodes a single project', () async {
    final (client, adapter) = testClient();
    adapter.get('/projects/42', fixtureJson('project'));

    final project = await ProjectsRepository(client).get(42);

    expect(project.id, 42);
    expect(project.pathWithNamespace, 'calico/glam');
    expect(project.owner?.username, 'calico');
    expect(project.topics, ['flutter', 'gitlab']);
  });

  test('get url-encodes string paths', () async {
    final (client, adapter) = testClient();
    adapter.get('/projects/group%2Fsub', fixtureJson('project'));

    await ProjectsRepository(client).get('group/sub');

    expect(adapter.lastRequest!.path, '/projects/group%2Fsub');
  });

  test('star/unstar post to the right endpoints', () async {
    final (client, adapter) = testClient();
    adapter
      ..post('/projects/42/star', fixtureJson('project'))
      ..post('/projects/42/unstar', fixtureJson('project'));
    final repo = ProjectsRepository(client);

    await repo.star(42);
    await repo.unstar(42);

    expect(adapter.requestsTo('POST', '/projects/42/star'), hasLength(1));
    expect(adapter.requestsTo('POST', '/projects/42/unstar'), hasLength(1));
  });

  test('fork posts to the fork endpoint', () async {
    final (client, adapter) = testClient();
    adapter.post('/projects/42/fork', fixtureJson('project'));

    await ProjectsRepository(client).fork(42);

    expect(adapter.requestsTo('POST', '/projects/42/fork'), hasLength(1));
  });

  group('settings', () {
    test('updateProject puts the changed fields only', () async {
      final (client, adapter) = testClient();
      adapter.put('/projects/42', fixtureJson('project'));
      final repo = ProjectsRepository(client);

      await repo.updateProject(
        42,
        name: 'New name',
        visibility: 'internal',
        topics: ['dart', 'flutter'],
        issuesEnabled: false,
        sharedRunnersEnabled: false,
        groupRunnersEnabled: true,
        approvalsBeforeMerge: 2,
        mergeMethod: 'ff',
        onlyAllowMergeIfPipelineSucceeds: true,
        onlyAllowMergeIfAllDiscussionsAreResolved: true,
        publicJobs: true,
        buildTimeout: 7200,
        autoCancelPendingPipelines: 'disabled',
        ciForwardDeploymentEnabled: true,
        ciSeparatedCaches: true,
        keepLatestArtifact: false,
        ciConfigPath: 'ci/main.yml',
      );

      expect(adapter.lastRequest!.data, {
        'name': 'New name',
        'visibility': 'internal',
        'topics': ['dart', 'flutter'],
        'issues_enabled': false,
        'shared_runners_enabled': false,
        'group_runners_enabled': true,
        'approvals_before_merge': 2,
        'merge_method': 'ff',
        'only_allow_merge_if_pipeline_succeeds': true,
        'only_allow_merge_if_all_discussions_are_resolved': true,
        'public_jobs': true,
        'build_timeout': 7200,
        'auto_cancel_pending_pipelines': 'disabled',
        'ci_forward_deployment_enabled': true,
        'ci_separated_caches': true,
        'keep_latest_artifact': false,
        'ci_config_path': 'ci/main.yml',
      });
    });

    test('archive and unarchive post to their endpoints', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/archive', fixtureJson('project'))
        ..post('/projects/42/unarchive', fixtureJson('project'));
      final repo = ProjectsRepository(client);

      await repo.archive(42);
      await repo.unarchive(42);

      expect(adapter.requestsTo('POST', '/projects/42/archive'), hasLength(1));
      expect(
        adapter.requestsTo('POST', '/projects/42/unarchive'),
        hasLength(1),
      );
    });
  });

  group('variables', () {
    test('lists and decodes variables', () async {
      final (client, adapter) = testClient();
      adapter.get('/projects/42/variables', fixtureJson('variables'));
      final repo = ProjectsRepository(client);

      final vars = await repo.variables(42);

      expect(vars, hasLength(2));
      expect(vars.first.key, 'DEPLOY_TOKEN');
      expect(vars.first.protected_, isTrue);
      expect(vars.first.masked, isTrue);
      expect(vars.first.environmentScope, 'production');
      expect(vars.last.variableType, 'file');
    });

    test('create and update send the right bodies', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/variables',
          (fixtureJson('variables') as List).first,
        )
        ..put(
          '/projects/42/variables/DEPLOY_TOKEN',
          (fixtureJson('variables') as List).first,
        );
      final repo = ProjectsRepository(client);

      await repo.createVariable(
        42,
        key: 'DEPLOY_TOKEN',
        value: 'v2',
        protected_: true,
        masked: true,
        environmentScope: 'production',
      );
      await repo.updateVariable(42, 'DEPLOY_TOKEN', value: 'v3');

      expect(adapter.requestsTo('POST', '/projects/42/variables').single.data, {
        'key': 'DEPLOY_TOKEN',
        'value': 'v2',
        'protected': true,
        'masked': true,
        'environment_scope': 'production',
      });
      expect(
        adapter
            .requestsTo('PUT', '/projects/42/variables/DEPLOY_TOKEN')
            .single
            .data,
        {'value': 'v3'},
      );
    });

    test('deleteVariable deletes by key', () async {
      final (client, adapter) = testClient();
      adapter.delete('/projects/42/variables/OLD');
      final repo = ProjectsRepository(client);

      await repo.deleteVariable(42, 'OLD');

      expect(
        adapter.requestsTo('DELETE', '/projects/42/variables/OLD'),
        hasLength(1),
      );
    });
  });
}
