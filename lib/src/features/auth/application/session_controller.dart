import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/auth/data/auth_repository.dart';
import 'package:glam/src/features/auth/domain/session.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// Owns the sign-in lifecycle: restores a stored session on boot,
/// validates new credentials, and clears everything on sign-out.
class SessionController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final stored = await ref.read(sessionStorageProvider).read();
    if (stored == null) {
      return null;
    }
    try {
      final client = GitLabApiClient(
        baseUrl: stored.baseUrl,
        token: stored.token,
      );
      final user = await AuthRepository(client).fetchCurrentUser();
      return Session(baseUrl: stored.baseUrl, token: stored.token, user: user);
    } on ApiException catch (e) {
      if (e.isAuthFailure) {
        await ref.read(sessionStorageProvider).clear();
        return null;
      }
      rethrow;
    }
  }

  /// Validates the token against the given instance and, on success,
  /// persists and activates the session.
  Future<void> signIn({required String baseUrl, required String token}) async {
    final normalized = GitLabApiClient.normalizeInstanceUrl(baseUrl);
    final client = GitLabApiClient(baseUrl: normalized, token: token);
    final user = await AuthRepository(client).fetchCurrentUser();
    final session = Session(baseUrl: normalized, token: token, user: user);
    await ref
        .read(sessionStorageProvider)
        .write(StoredSession(baseUrl: normalized, token: token));
    state = AsyncData(session);
  }

  /// Swaps the stored token after a rotation so the session stays
  /// alive under the new credential.
  Future<void> replaceToken(String token) async {
    final session = state.value;
    if (session == null) {
      return;
    }
    await ref
        .read(sessionStorageProvider)
        .write(StoredSession(baseUrl: session.baseUrl, token: token));
    state = AsyncData(
      Session(baseUrl: session.baseUrl, token: token, user: session.user),
    );
  }

  /// Replaces the cached user after a profile edit so headers and
  /// comment ownership checks see the new data.
  void updateUser(GitLabUser user) {
    final session = state.value;
    if (session == null) {
      return;
    }
    state = AsyncData(
      Session(baseUrl: session.baseUrl, token: session.token, user: user),
    );
  }

  Future<void> signOut() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}
