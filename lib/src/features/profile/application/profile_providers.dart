import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/projects/application/projects_providers.dart';
import 'package:glam/src/features/projects/domain/project.dart';

/// Any user's public profile (`/users/:id`).
final userProvider = FutureProvider.family<GitLabUser, int>(
  (ref, id) => ref.watch(authRepositoryProvider).fetchUser(id),
);

/// Projects a user owns or contributes to.
final userProjectsProvider = FutureProvider.family<List<Project>, int>(
  (ref, id) => ref.watch(projectsRepositoryProvider).byUser(id),
);

/// Projects a user has starred.
final userStarredProvider = FutureProvider.family<List<Project>, int>(
  (ref, id) => ref.watch(projectsRepositoryProvider).starredBy(id),
);
