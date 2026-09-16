import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/presentation/login_screen.dart';
import 'package:glam/src/features/home/presentation/app_shell.dart';
import 'package:glam/src/features/home/presentation/dashboard_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_detail_screen.dart';
import 'package:glam/src/features/issues/presentation/issues_screen.dart';
import 'package:glam/src/features/projects/presentation/project_detail_screen.dart';
import 'package:glam/src/features/projects/presentation/projects_screen.dart';
import 'package:glam/src/features/repository/presentation/commit_detail_screen.dart';
import 'package:glam/src/features/repository/presentation/file_viewer_screen.dart';
import 'package:glam/src/features/repository/presentation/files_screen.dart';
import 'package:glam/src/features/settings/presentation/settings_screen.dart';

/// go_router wiring. The shell is a [StatefulShellRoute] so each top
/// section keeps its own stack and scroll position.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier();
  ref
    ..onDispose(refresh.dispose)
    ..listen(sessionProvider, (_, _) => refresh.ping());

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loggedIn = session.value != null;
      final onLogin = state.matchedLocation == Routes.login;

      if (session.isLoading) {
        return null;
      }
      if (!loggedIn && !onLogin) {
        return Routes.login;
      }
      if (loggedIn && onLogin) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.projects,
                builder: (context, state) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'tree',
                        builder: (context, state) => Scaffold(
                          appBar: AppBar(title: const Text('Files')),
                          body: FilesScreen(
                            projectId: state.pathParameters['id']!,
                            defaultRef: state.uri.queryParameters['ref'],
                            path: state.uri.queryParameters['path'],
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'blob',
                        builder: (context, state) => FileViewerScreen(
                          projectId: state.pathParameters['id']!,
                          path: state.uri.queryParameters['path'] ?? '',
                          ref: state.uri.queryParameters['ref'],
                        ),
                      ),
                      GoRoute(
                        path: 'commit/:sha',
                        builder: (context, state) => CommitDetailScreen(
                          projectId: state.pathParameters['id']!,
                          sha: state.pathParameters['sha']!,
                        ),
                      ),
                      GoRoute(
                        path: 'issues/:iid',
                        builder: (context, state) => IssueDetailScreen(
                          projectId: state.pathParameters['id']!,
                          iid: int.parse(state.pathParameters['iid']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.issues,
                builder: (context, state) => const IssuesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
