import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for auth token persistence.
class SecureStorage {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user_json';

  final FlutterSecureStorage _storage;

  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<void> writeToken(String token) =>
      _storage.write(key: _kToken, value: token);
  Future<void> deleteToken() => _storage.delete(key: _kToken);

  Future<String?> readUser() => _storage.read(key: _kUser);
  Future<void> writeUser(String json) =>
      _storage.write(key: _kUser, value: json);
  Future<void> deleteUser() => _storage.delete(key: _kUser);

  Future<void> clear() async {
    await deleteToken();
    await deleteUser();
  }
}
