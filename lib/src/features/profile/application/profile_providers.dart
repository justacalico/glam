import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/auth/domain/user_counts.dart';
import 'package:glam/src/features/profile/domain/membership.dart';
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

/// Users following [id].
final userFollowersProvider = FutureProvider.family<List<GitLabUser>, int>(
  (ref, id) => ref.watch(authRepositoryProvider).userFollowers(id),
);

/// Users [id] follows.
final userFollowingProvider = FutureProvider.family<List<GitLabUser>, int>(
  (ref, id) => ref.watch(authRepositoryProvider).userFollowing(id),
);

/// Ids of users the signed-in account follows. REST exposes no
/// `is_following` flag on `/users/:id`, so the follow button checks
/// membership in this set.
final myFollowedProvider = FutureProvider<Set<int>>(
  (ref) async => {
    for (final u in await ref.watch(authRepositoryProvider).myFollowed()) u.id,
  },
);

/// Groups and projects the signed-in account belongs to.
final myMembershipsProvider = FutureProvider<List<Membership>>(
  (ref) => ref.watch(authRepositoryProvider).userMemberships(),
);

/// Queue sizes for dashboard badges (`/user/counts`).
final myCountsProvider = FutureProvider<UserCounts>(
  (ref) => ref.watch(authRepositoryProvider).userCounts(),
);
