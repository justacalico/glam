import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glam/src/features/auth/domain/session.dart';

/// Persists the sign-in session (instance URL + personal access token)
/// in the platform's secure enclave/keychain.
class SessionStorage {
  const SessionStorage(this._storage);

  static const String _key = 'glam.session';

  final FlutterSecureStorage _storage;

  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return StoredSession.fromJson(json);
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(StoredSession session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() => _storage.delete(key: _key);
}
