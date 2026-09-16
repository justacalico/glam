import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/features/activity/presentation/activity_screen.dart';
import 'package:glam/src/features/activity/presentation/notifications_screen.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/presentation/login_screen.dart';
import 'package:glam/src/features/home/presentation/app_shell.dart';
import 'package:glam/src/features/groups/presentation/group_detail_screen.dart';
import 'package:glam/src/features/groups/presentation/groups_screen.dart';
import 'package:glam/src/features/home/presentation/dashboard_screen.dart';
import 'package:glam/src/features/issues/presentation/issue_detail_screen.dart';
import 'package:glam/src/features/environments/presentation/environment_detail_screen.dart';
import 'package:glam/src/features/registry/presentation/registry_tags_screen.dart';
import 'package:glam/src/features/issues/presentation/issues_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/merge_requests_screen.dart';
import 'package:glam/src/features/merge_requests/presentation/mr_detail_screen.dart';
import 'package:glam/src/features/milestones/presentation/milestones_screen.dart';
import 'package:glam/src/features/pipelines/presentation/job_detail_screen.dart';
import 'package:glam/src/features/pipelines/presentation/pipeline_detail_screen.dart';
import 'package:glam/src/features/projects/presentation/project_detail_screen.dart';
import 'package:glam/src/features/projects/presentation/project_settings_screen.dart';
import 'package:glam/src/features/profile/presentation/profile_screen.dart';
import 'package:glam/src/features/projects/presentation/projects_screen.dart';
import 'package:glam/src/features/repository/presentation/blame_screen.dart';
import 'package:glam/src/features/repository/presentation/compare_screen.dart';
import 'package:glam/src/features/repository/presentation/commit_detail_screen.dart';
import 'package:glam/src/features/repository/presentation/file_viewer_screen.dart';
import 'package:glam/src/features/repository/presentation/files_screen.dart';
import 'package:glam/src/features/search/presentation/search_screen.dart';
import 'package:glam/src/features/settings/presentation/settings_screen.dart';
import 'package:glam/src/features/snippets/presentation/snippet_detail_screen.dart';
import 'package:glam/src/features/snippets/presentation/snippets_screen.dart';
import 'package:glam/src/features/todos/presentation/todos_screen.dart';
import 'package:glam/src/features/wiki/presentation/wiki_screen.dart';

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
                        path: 'blame',
                        builder: (context, state) => BlameScreen(
                          projectId: state.pathParameters['id']!,
                          path: state.uri.queryParameters['path'] ?? '',
                          ref: state.uri.queryParameters['ref'],
                        ),
                      ),
                      GoRoute(
                        path: 'compare',
                        builder: (context, state) => CompareScreen(
                          projectId: state.pathParameters['id']!,
                          from: state.uri.queryParameters['from'],
                          to: state.uri.queryParameters['to'],
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
                      GoRoute(
                        path: 'mrs/:iid',
                        builder: (context, state) => MrDetailScreen(
                          projectId: state.pathParameters['id']!,
                          iid: int.parse(state.pathParameters['iid']!),
                        ),
                      ),
                      GoRoute(
                        path: 'pipelines/:pid',
                        builder: (context, state) => PipelineDetailScreen(
                          projectId: state.pathParameters['id']!,
                          pipelineId: int.parse(state.pathParameters['pid']!),
                        ),
                      ),
                      GoRoute(
                        path: 'search',
                        builder: (context, state) => SearchScreen(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) => ProjectSettingsScreen(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'milestones/:mid',
                        builder: (context, state) => MilestoneDetailScreen(
                          loc: (
                            projectId: state.pathParameters['id']!,
                            milestoneId: int.parse(
                              state.pathParameters['mid']!,
                            ),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'wiki/:slug',
                        builder: (context, state) => WikiPageScreen(
                          loc: (
                            projectId: state.pathParameters['id']!,
                            slug: Uri.decodeComponent(
                              state.pathParameters['slug']!,
                            ),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'jobs/:jid',
                        builder: (context, state) => JobDetailScreen(
                          projectId: state.pathParameters['id']!,
                          jobId: int.parse(state.pathParameters['jid']!),
                        ),
                      ),
                      GoRoute(
                        path: 'registry/:rid',
                        builder: (context, state) {
                          final extra =
                              state.extra as ({Object project, String name})?;
                          return RegistryTagsScreen(
                            loc: (
                              project:
                                  extra?.project ?? state.pathParameters['id']!,
                              repoId: int.parse(state.pathParameters['rid']!),
                            ),
                            repoName: extra?.name,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'environments/:eid',
                        builder: (context, state) => EnvironmentDetailScreen(
                          loc: (
                            project: state.pathParameters['id']!,
                            envId: int.parse(state.pathParameters['eid']!),
                          ),
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
                path: Routes.mergeRequests,
                builder: (context, state) => const MergeRequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.todos,
                builder: (context, state) => const TodosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.groups,
                builder: (context, state) => const GroupsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        GroupDetailScreen(groupId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'search',
                        builder: (context, state) =>
                            SearchScreen(groupId: state.pathParameters['id']!),
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
                path: Routes.snippets,
                builder: (context, state) => const SnippetsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SnippetDetailScreen(
                      loc: (
                        id: int.parse(state.pathParameters['id']!),
                        projectId: state.uri.queryParameters['project'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (context, state) => const SearchScreen(),
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
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) {
          final ref = ProviderScope.containerOf(context);
          final session = ref.read(sessionProvider).value;
          return ProfileScreen(userId: session?.user.id ?? 0);
        },
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) =>
            ProfileScreen(userId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
