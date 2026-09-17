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

  test('updateProfile puts the editable fields', () async {
    final (client, adapter) = testClient();
    adapter.put('/user', fixtureJson('user'));

    final user = await AuthRepository(client).updateProfile(
      name: 'Calico Cat',
      bio: 'Building things',
      pronouns: 'she/her',
      jobTitle: 'Engineer',
    );

    expect(user.pronouns, 'she/her');
    expect(user.jobTitle, 'Engineer');
    final sent = adapter.lastRequest!.data as Map;
    expect(sent['name'], 'Calico Cat');
    expect(sent['job_title'], 'Engineer');
    expect(sent.containsKey('website_url'), isFalse);
  });

  test('updateStatus puts emoji and message', () async {
    final (client, adapter) = testClient();
    adapter.put(
      '/user/status',
      const {'emoji': '🌴', 'message': 'On vacation'},
    );

    final status = await AuthRepository(
      client,
    ).updateStatus(emoji: '🌴', message: 'On vacation');

    expect(status.emoji, '🌴');
    expect(status.message, 'On vacation');
    final sent = adapter.lastRequest!.data as Map;
    expect(sent['emoji'], '🌴');
    expect(sent['message'], 'On vacation');
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
