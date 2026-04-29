import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final SecureStorage _storage;

  Future<AuthUser> login({
    required String email,
    required String password,
    String deviceName = 'mobile-pos',
  }) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/auth/login',
      method: 'POST',
      body: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );
    final token = data['token'] as String;
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    await _storage.writeToken(token);
    await _storage.writeUser(jsonEncode(user.toJson()));
    return user;
  }

  Future<AuthUser?> restore() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    final raw = await _storage.readUser();
    if (raw != null) {
      try {
        return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {/* ignore, will re-fetch */}
    }
    try {
      final data = await _api.request<Map<String, dynamic>>('/auth/me');
      final user = AuthUser.fromJson(data);
      await _storage.writeUser(jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.request<dynamic>('/auth/logout', method: 'POST');
    } catch (_) {/* offline logout still clears token */}
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  );
});
