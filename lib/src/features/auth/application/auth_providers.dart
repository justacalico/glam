import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/storage/session_storage.dart';
import 'package:glam/src/core/storage/settings_storage.dart';
import 'package:glam/src/features/auth/application/session_controller.dart';
import 'package:glam/src/features/auth/data/auth_repository.dart';
import 'package:glam/src/features/auth/domain/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main` with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(ref.watch(secureStorageProvider)),
);

final settingsStorageProvider = Provider<SettingsStorage>(
  (ref) => SettingsStorage(ref.watch(sharedPreferencesProvider)),
);

/// The active, validated session. `null` when signed out.
final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(
  SessionController.new,
);

/// API client bound to the current session's instance and token.
final apiClientProvider = Provider<GitLabApiClient>((ref) {
  final session = ref.watch(sessionProvider).value;
  return GitLabApiClient(
    baseUrl: session?.baseUrl ?? 'https://gitlab.com',
    token: session?.token,
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
