import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/auth/domain/session.dart';
import 'package:glam/src/features/auth/domain/user.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('GitLabUser.fromJson', () {
    test('decodes the full fixture', () {
      final user = GitLabUser.fromJson(
        fixtureJson('user')! as Map<String, dynamic>,
      );
      expect(user.username, 'calico');
      expect(user.avatarUrl, contains('avatar.png'));
      expect(user.followers, 12);
      expect(user.following, 34);
      expect(user.isAdmin, isFalse);
      expect(user.createdAt, isNotNull);
    });

    test('decodes embedded status', () {
      final user = GitLabUser.fromJson({
        'id': 1,
        'username': 'x',
        'status': {'emoji': 'beach', 'message': 'on holiday'},
      });
      expect(user.statusEmoji, 'beach');
      expect(user.statusMessage, 'on holiday');
    });

    test('minimal payload', () {
      final user = GitLabUser.fromJson({'id': 2});
      expect(user.id, 2);
      expect(user.username, '');
      expect(user.avatarUrl, isNull);
    });
  });

  group('StoredSession', () {
    test('round-trips through json', () {
      const session = StoredSession(
        baseUrl: 'https://gitlab.example.com',
        token: 'token123',
      );
      final decoded = StoredSession.fromJson(session.toJson());
      expect(decoded, session);
    });

    test('handles missing fields', () {
      final session = StoredSession.fromJson({});
      expect(session.baseUrl, 'https://gitlab.com');
      expect(session.token, '');
    });
  });
}
