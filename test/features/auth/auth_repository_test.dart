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
    adapter.put('/user/status', const {
      'emoji': '🌴',
      'message': 'On vacation',
    });

    final status = await AuthRepository(
      client,
    ).updateStatus(emoji: '🌴', message: 'On vacation');

    expect(status.emoji, '🌴');
    expect(status.message, 'On vacation');
    final sent = adapter.lastRequest!.data as Map;
    expect(sent['emoji'], '🌴');
    expect(sent['message'], 'On vacation');
  });

  test('follow lists and follow/unfollow endpoints', () async {
    final (client, adapter) = testClient();
    final user = {'id': 7, 'username': 'calico', 'name': 'Calico'};
    adapter
      ..get('/users/7/followers', [user])
      ..get('/users/7/followed_users', [user])
      ..get('/user/followed_users', [user])
      ..post('/users/7/follow', user)
      ..post('/users/7/unfollow', user);
    final repo = AuthRepository(client);

    expect((await repo.userFollowers(7)).single.id, 7);
    expect((await repo.userFollowing(7)).single.username, 'calico');
    expect((await repo.myFollowed()).single.id, 7);

    await repo.followUser(7);
    expect(adapter.requestsTo('POST', '/users/7/follow'), hasLength(1));
    await repo.unfollowUser(7);
    expect(adapter.requestsTo('POST', '/users/7/unfollow'), hasLength(1));
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
