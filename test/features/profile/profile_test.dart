import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/data/auth_repository.dart';
import 'package:glam/src/features/profile/application/profile_providers.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  test('userProvider loads a public profile', () async {
    final (client, adapter) = testClient();
    adapter.get('/users/7', fixtureJson('user'));
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepository(client)),
      ],
    );
    addTearDown(container.dispose);

    final user = await container.read(userProvider(7).future);

    expect(user.username, 'calico');
    expect(user.bio, 'Building things');
    expect(user.followers, 12);
    expect(adapter.lastRequest!.path, '/users/7');
  });

  test('project providers hit the user-scoped endpoints', () async {
    final (client, adapter) = testClient();
    adapter
      ..get('/users/7/projects', [fixtureJson('project')])
      ..get('/users/7/starred_projects', [fixtureJson('project')]);
    final container = ProviderContainer(
      overrides: [
        projectsRepositoryProvider.overrideWithValue(
          ProjectsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);

    final projects = await container.read(userProjectsProvider(7).future);
    final starred = await container.read(userStarredProvider(7).future);

    expect(projects.single.name, 'Glam');
    expect(starred.single.name, 'Glam');
    expect(adapter.requestsTo('GET', '/users/7/projects'), hasLength(1));
    expect(
      adapter.requestsTo('GET', '/users/7/starred_projects'),
      hasLength(1),
    );
  });
}
