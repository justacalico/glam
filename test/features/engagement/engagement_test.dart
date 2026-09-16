import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/application/session_controller.dart';
import 'package:glam/src/features/auth/domain/session.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/engagement/application/engagement_providers.dart';
import 'package:glam/src/features/issues/application/issues_providers.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/merge_requests/application/mr_providers.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

import '../../helpers/fake_dio_adapter.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_client.dart';

class _SignedIn extends SessionController {
  @override
  Future<Session?> build() async => const Session(
    baseUrl: 'https://gitlab.example.com',
    token: 't',
    user: GitLabUser(id: 7, username: 'me', name: 'Me Myself'),
  );
}

void main() {
  group('AwardEmoji model', () {
    test('parses name, user, and resolves the glyph', () {
      final award = AwardEmoji.fromJson(
        (fixtureJson('award_emojis') as List).first as Map<String, dynamic>,
      );
      expect(award.id, 101);
      expect(award.name, 'thumbsup');
      expect(award.user?.username, 'me');
      expect(award.glyph, '👍');
    });

    test('unknown names fall back to the raw name', () {
      const award = AwardEmoji(id: 1, name: 'custom_party_blob');
      expect(award.glyph, 'custom_party_blob');
    });
  });

  group('issue engagement endpoints', () {
    test('lists awards on the issue and on a note', () async {
      final (client, adapter) = testClient();
      adapter
        ..get('/projects/42/issues/12/award_emoji', fixtureJson('award_emojis'))
        ..get(
          '/projects/42/issues/12/notes/501/award_emoji',
          fixtureJson('award_emojis'),
        );
      final repo = IssuesRepository(client);

      final top = await repo.awardEmojis(42, 12);
      final note = await repo.noteAwardEmojis(42, 12, 501);

      expect(top, hasLength(3));
      expect(note.first.user?.name, 'Me Myself');
    });

    test('award posts the emoji name; noteId targets the note', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/issues/12/award_emoji',
          (fixtureJson('award_emojis') as List).first,
        )
        ..post(
          '/projects/42/issues/12/notes/501/award_emoji',
          (fixtureJson('award_emojis') as List).first,
        );
      final repo = IssuesRepository(client);

      await repo.award(42, 12, 'rocket');
      await repo.award(42, 12, 'eyes', noteId: 501);

      final requests = adapter.requestsTo(
        'POST',
        '/projects/42/issues/12/award_emoji',
      );
      expect(requests.single.data, {'name': 'rocket'});
      expect(
        adapter
            .requestsTo('POST', '/projects/42/issues/12/notes/501/award_emoji')
            .single
            .data,
        {'name': 'eyes'},
      );
    });

    test('removeAward deletes the award by id', () async {
      final (client, adapter) = testClient();
      adapter
        ..delete('/projects/42/issues/12/award_emoji/101')
        ..delete('/projects/42/issues/12/notes/501/award_emoji/102');
      final repo = IssuesRepository(client);

      await repo.removeAward(42, 12, 101);
      await repo.removeAward(42, 12, 102, noteId: 501);

      expect(
        adapter.requestsTo('DELETE', '/projects/42/issues/12/award_emoji/101'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/issues/12/notes/501/award_emoji/102',
        ),
        hasLength(1),
      );
    });

    test('setSubscribed posts to subscribe/unsubscribe', () async {
      final (client, adapter) = testClient();
      adapter
        ..post(
          '/projects/42/issues/12/subscribe',
          (fixtureJson('issues') as List).first,
        )
        ..post(
          '/projects/42/issues/12/unsubscribe',
          (fixtureJson('issues') as List).first,
        );
      final repo = IssuesRepository(client);

      await repo.setSubscribed(42, 12, subscribed: true);
      await repo.setSubscribed(42, 12, subscribed: false);

      expect(
        adapter.requestsTo('POST', '/projects/42/issues/12/subscribe'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/issues/12/unsubscribe'),
        hasLength(1),
      );
    });

    test('time tracking sends the duration as a query param', () async {
      final (client, adapter) = testClient();
      adapter
        ..post('/projects/42/issues/12/time_estimate', const {})
        ..post('/projects/42/issues/12/add_spent_time', const {})
        ..post('/projects/42/issues/12/reset_spent_time', const {});
      final repo = IssuesRepository(client);

      await repo.setTimeEstimate(42, 12, '2h');
      await repo.addTimeSpent(42, 12, '30m');
      await repo.resetTimeSpent(42, 12);

      expect(
        adapter
            .requestsTo('POST', '/projects/42/issues/12/time_estimate')
            .single
            .queryParameters['duration'],
        '2h',
      );
      expect(
        adapter
            .requestsTo('POST', '/projects/42/issues/12/add_spent_time')
            .single
            .queryParameters['duration'],
        '30m',
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/issues/12/reset_spent_time'),
        hasLength(1),
      );
    });
  });

  group('MR engagement endpoints', () {
    test('award endpoints use the merge_requests path', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/merge_requests/5/award_emoji',
          fixtureJson('award_emojis'),
        )
        ..post(
          '/projects/42/merge_requests/5/award_emoji',
          (fixtureJson('award_emojis') as List).first,
        )
        ..delete('/projects/42/merge_requests/5/award_emoji/101');
      final repo = MergeRequestsRepository(client);

      final awards = await repo.awardEmojis(42, 5);
      await repo.award(42, 5, 'heart');
      await repo.removeAward(42, 5, 101);

      expect(awards, hasLength(3));
      expect(
        adapter
            .requestsTo('POST', '/projects/42/merge_requests/5/award_emoji')
            .single
            .data,
        {'name': 'heart'},
      );
      expect(
        adapter.requestsTo(
          'DELETE',
          '/projects/42/merge_requests/5/award_emoji/101',
        ),
        hasLength(1),
      );
    });

    test('note awards and subscription hit nested paths', () async {
      final (client, adapter) = testClient();
      adapter
        ..get(
          '/projects/42/merge_requests/5/notes/77/award_emoji',
          fixtureJson('award_emojis'),
        )
        ..post(
          '/projects/42/merge_requests/5/subscribe',
          (fixtureJson('mrs') as List).first,
        );
      final repo = MergeRequestsRepository(client);

      await repo.noteAwardEmojis(42, 5, 77);
      final mr = await repo.setSubscribed(42, 5, subscribed: true);

      expect(mr, isA<MergeRequest>());
      expect(
        adapter.requestsTo('POST', '/projects/42/merge_requests/5/subscribe'),
        hasLength(1),
      );
    });
  });

  group('model fields', () {
    test('Issue parses subscribed and time tracking', () {
      final issue = Issue.fromJson({
        'id': 1,
        'iid': 2,
        'project_id': 3,
        'title': 'x',
        'state': 'opened',
        'subscribed': true,
        'time_estimate': 7200,
        'total_time_spent': 1800,
      });
      expect(issue.subscribed, isTrue);
      expect(issue.timeEstimate, 7200);
      expect(issue.timeSpent, 1800);
    });

    test('MergeRequest parses subscribed', () {
      final mr = MergeRequest.fromJson(const {'subscribed': true});
      expect(mr.subscribed, isTrue);
    });
  });

  group('awardEmojisProvider', () {
    late FakeDioAdapter adapter;
    late ProviderContainer container;

    const loc = (kind: 'issue', project: 42, iid: 12, noteId: null);

    setUp(() {
      final (client, a) = testClient();
      adapter = a;
      container = ProviderContainer(
        overrides: [
          issuesRepositoryProvider.overrideWithValue(IssuesRepository(client)),
          mrRepositoryProvider.overrideWithValue(
            MergeRequestsRepository(client),
          ),
          sessionProvider.overrideWith(_SignedIn.new),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loads awards for the issue', () async {
      adapter.get(
        '/projects/42/issues/12/award_emoji',
        fixtureJson('award_emojis'),
      );

      final awards = await container.read(awardEmojisProvider(loc).future);

      expect(awards, hasLength(3));
    });

    test('toggle adds a new reaction when the user has none', () async {
      adapter
        ..get('/projects/42/issues/12/award_emoji', fixtureJson('award_emojis'))
        ..post(
          '/projects/42/issues/12/award_emoji',
          (fixtureJson('award_emojis') as List).first,
        );

      await container.read(awardEmojisProvider(loc).future);
      await container.read(awardEmojisProvider(loc).notifier).toggle('rocket');

      final post = adapter.requestsTo(
        'POST',
        '/projects/42/issues/12/award_emoji',
      );
      expect(post.single.data, {'name': 'rocket'});
    });

    test("toggle removes the current user's existing reaction", () async {
      adapter
        ..get('/projects/42/issues/12/award_emoji', fixtureJson('award_emojis'))
        ..delete('/projects/42/issues/12/award_emoji/101');

      await container.read(awardEmojisProvider(loc).future);
      await container
          .read(awardEmojisProvider(loc).notifier)
          .toggle('thumbsup');

      // Award 101 belongs to user 7 (the signed-in user), so it gets
      // deleted instead of posting a duplicate.
      expect(
        adapter.requestsTo('DELETE', '/projects/42/issues/12/award_emoji/101'),
        hasLength(1),
      );
      expect(
        adapter.requestsTo('POST', '/projects/42/issues/12/award_emoji'),
        isEmpty,
      );
    });

    test('kind mr routes to the MR repository', () async {
      adapter.get(
        '/projects/42/merge_requests/5/award_emoji',
        fixtureJson('award_emojis'),
      );

      const mrLoc = (kind: 'mr', project: 42, iid: 5, noteId: null);
      final awards = await container.read(awardEmojisProvider(mrLoc).future);

      expect(awards, hasLength(3));
    });
  });
}
