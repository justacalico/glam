import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/auth/data/auth_repository.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

void main() {
  test('fetchCurrentUser decodes the user', () async {
    final (client, adapter) = testClient();
    adapter.get('/user', fixtureJson('user'));

    final user = await AuthRepository(client).fetchCurrentUser();

    expect(user.id, 1);
    expect(user.username, 'calico');
    expect(user.name, 'Calico Cat');
    expect(user.followers, 12);
    expect(adapter.lastRequest!.path, '/user');
  });

  test('fetchUser hits /users/:id', () async {
    final (client, adapter) = testClient();
    adapter.get('/users/7', fixtureJson('user'));

    final user = await AuthRepository(client).fetchUser(7);
    expect(user.username, 'calico');
    expect(adapter.lastRequest!.path, '/users/7');
  });

  test('fetchUserByUsername returns first match', () async {
    final (client, adapter) = testClient();
    adapter.get('/users', fixtureList('user'));

    final user = await AuthRepository(client).fetchUserByUsername('calico');
    expect(user.username, 'calico');
    expect(adapter.lastRequest!.queryParameters['username'], 'calico');
  });

  test('fetchUserByUsername throws when nobody matches', () async {
    final (client, adapter) = testClient();
    adapter.get('/users', []);

    await expectLater(
      AuthRepository(client).fetchUserByUsername('nobody'),
      throwsA(isA<FormatException>()),
    );
  });
}
