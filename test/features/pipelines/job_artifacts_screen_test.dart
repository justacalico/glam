import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/app/theme/app_theme.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/pipelines/presentation/job_artifacts_screen.dart';

import '../../helpers/test_client.dart';
import 'package:glam/l10n/app_localizations.dart';

Widget _app(Widget child, GitLabApiClient client) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(client)],
    child: MaterialApp(
    theme: GlamTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
  );
}

void main() {
  testWidgets('job artifacts screen lists entries from the tree', (
    tester,
  ) async {
    final (client, adapter) = testClient();
    adapter.get('/projects/42/jobs/5001/artifacts/tree', [
      {'name': 'a.txt', 'path': 'a.txt', 'type': 'blob', 'size': 5},
      {'name': 'c.txt', 'path': 'b/c.txt', 'type': 'blob', 'size': 10},
    ]);

    await tester.pumpWidget(
      _app(const JobArtifactsScreen(projectId: 42, jobId: 5001), client),
    );
    await tester.pumpAndSettle();

    expect(find.text('a.txt'), findsOneWidget);
    expect(find.text('b/c.txt'), findsOneWidget);
  });

  testWidgets('tapping an entry shows its contents', (tester) async {
    final (client, adapter) = testClient();
    adapter
      ..get('/projects/42/jobs/5001/artifacts/tree', [
        {'name': 'a.txt', 'path': 'a.txt', 'type': 'blob', 'size': 2},
      ])
      ..get(
        '/projects/42/jobs/5001/artifacts/a.txt',
        Uint8List.fromList('hi'.codeUnits),
      );

    await tester.pumpWidget(
      _app(const JobArtifactsScreen(projectId: 42, jobId: 5001), client),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('a.txt'));
    await tester.pumpAndSettle();

    expect(find.text('hi'), findsOneWidget);
  });
}
