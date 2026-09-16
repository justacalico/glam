import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/router.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/presentation/login_screen.dart';
import 'package:glam/src/features/home/presentation/app_shell.dart';
import 'package:glam/src/features/home/presentation/dashboard_screen.dart';
import 'package:glam/src/features/projects/presentation/projects_screen.dart';
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
