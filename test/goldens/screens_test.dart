import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:glam/src/app/theme/app_theme.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/application/session_controller.dart';
import 'package:glam/src/features/auth/domain/session.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/home/presentation/dashboard_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_detail_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_detail_screen.dart';
import 'package:glam/src/features/pipelines/presentation/job_artifacts_screen.dart';
import 'package:glam/src/features/pipelines/presentation/pipelines_screen.dart';
import 'package:glam/src/features/projects/presentation/project_detail_screen.dart';
import 'package:glam/src/features/projects/presentation/projects_screen.dart';

import '../helpers/fake_dio_adapter.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_client.dart';

/// Renders real screens against the fake adapter and captures them
/// into `test/goldens/goldens/`. Regenerate with
/// `flutter test test/goldens --update-goldens`.
void main() {
  const phone = Size(430, 932);
  const desktop = Size(1440, 900);

  setUpAll(() async {
    await loadAppFonts();
    // cached_network_image resolves a cache dir through path_provider,
    // which has no plugin implementation under flutter_test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  testWidgets('dashboard', (tester) async {
    await withClock(Clock.fixed(DateTime(2024, 6, 3, 10)), () async {
      await _shot(tester, 'dashboard', const DashboardScreen(), size: phone);
    });
  });

  testWidgets('projects', (tester) async {
    await _shot(
      tester,
      'projects',
      const ProjectsScreen(),
      size: phone,
      stubs: (a) => a.get('/projects', fixtureList('project')),
    );
  });

  testWidgets('project overview', (tester) async {
    await _shot(
      tester,
      'project',
      const ProjectDetailScreen(projectId: '42'),
      size: phone,
      stubs: (a) {
        a
          ..get('/projects/42', fixtureJson('project'))
          ..get('/projects/42/languages', {'Dart': 91.4, 'Shell': 8.6});
      },
    );
  });

  testWidgets('issue detail', (tester) async {
    await _shot(
      tester,
      'issue',
      const IssueDetailScreen(projectId: 42, iid: 12),
      size: phone,
      stubs: (a) {
        a
          ..get('/projects/42/issues/12', (fixtureJson('issues') as List).first)
          ..get('/projects/42/issues/12/notes', fixtureJson('notes'))
          ..get(
            '/projects/42/issues/12/participants',
            fixtureJson('participants'),
          )
          ..get('/projects/42/issues/12/links', fixtureJson('issue_links'))
          ..get(
            '/projects/42/issues/12/related_merge_requests',
            fixtureJson('related_mrs'),
          )
          ..get('/projects/42/issues/12/closed_by', fixtureJson('related_mrs'))
          ..get(
            '/projects/42/issues/12/award_emoji',
            fixtureJson('award_emojis'),
          )
          ..get(
            '/projects/42/issues/12/notes/501/award_emoji',
            fixtureJson('award_emojis'),
          )
          ..get(
            '/projects/42/issues/12/notes/502/award_emoji',
            fixtureJson('award_emojis'),
          );
      },
    );
  });

  testWidgets('merge request', (tester) async {
    await _shot(
      tester,
      'merge_request',
      const MrDetailScreen(projectId: 42, iid: 7),
      size: desktop,
      stubs: (a) {
        a
          ..get(
            '/projects/42/merge_requests/7',
            (fixtureJson('mrs') as List).first,
          )
          ..get(
            '/projects/42/merge_requests/7/discussions',
            fixtureJson('discussions'),
          )
          ..get('/projects/42/merge_requests/7/approvals', {
            'approved': true,
            'approvals_required': 1,
            'approvals_left': 0,
            'approved_by': [
              {'user': fixtureJson('user')},
            ],
            'user_has_approved': false,
            'user_can_approve': true,
          })
          ..get(
            '/projects/42/merge_requests/7/participants',
            fixtureJson('participants'),
          )
          ..get(
            '/projects/42/merge_requests/7/closes_issues',
            fixtureJson('issues'),
          )
          ..get(
            '/projects/42/merge_requests/7/award_emoji',
            fixtureJson('award_emojis'),
          )
          ..get(
            '/projects/42/merge_requests/7/notes/500/award_emoji',
            fixtureJson('award_emojis'),
          )
          ..get(
            '/projects/42/merge_requests/7/notes/501/award_emoji',
            fixtureJson('award_emojis'),
          )
          ..get(
            '/projects/42/merge_requests/7/notes/502/award_emoji',
            fixtureJson('award_emojis'),
          );
      },
    );
  });

  testWidgets('pipelines', (tester) async {
    await _shot(
      tester,
      'pipelines',
      const PipelinesScreen(projectId: 42),
      size: phone,
      stubs: (a) => a
        ..get('/projects/42/pipelines', fixtureJson('pipelines'))
        ..get('/projects/42/members/all', fixtureJson('members'))
        ..get('/projects/42/repository/branches', fixtureJson('branches')),
    );
  });

  testWidgets('job artifacts', (tester) async {
    await _shot(
      tester,
      'artifacts',
      const JobArtifactsScreen(projectId: 42, jobId: 5001),
      size: phone,
      stubs: (a) => a.get('/projects/42/jobs/5001/artifacts/tree', [
        {
          'name': 'report.html',
          'path': 'coverage/report.html',
          'type': 'blob',
          'size': 184320,
        },
        {
          'name': 'app-release.apk',
          'path': 'dist/app-release.apk',
          'type': 'blob',
          'size': 52428800,
        },
        {
          'name': 'build.log',
          'path': 'logs/build.log',
          'type': 'blob',
          'size': 96256,
        },
      ]),
    );
  });
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget child, {
  required Size size,
  void Function(FakeDioAdapter adapter)? stubs,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final (client, adapter) = testClient();
  stubs?.call(adapter);
  final user = GitLabUser.fromJson(fixtureJson('user') as Map<String, dynamic>);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        sessionProvider.overrideWith(() => _StubSession(user)),
      ],
      // The extra Scaffold gives tab-body screens a Material ancestor;
      // full-screen children are Scaffolds themselves and nest fine.
      child: MaterialApp(
        theme: GlamTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
  // Providers resolve as microtasks; shimmer loops keep animating so a
  // fixed set of pumps beats pumpAndSettle here.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  await expectLater(
    find.byType(child.runtimeType),
    matchesGoldenFile('goldens/$name.png'),
  );
}

class _StubSession extends SessionController {
  _StubSession(this.user);

  final GitLabUser user;

  @override
  Future<Session?> build() async => Session(
    baseUrl: 'https://gitlab.example.com',
    token: 'golden',
    user: user,
  );
}
