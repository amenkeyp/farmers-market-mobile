import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthState {
  final AuthUser? user;
  final bool loading;
  final String? error;
  final bool restored;

  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.restored = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? loading,
    String? error,
    bool? restored,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        restored: restored ?? this.restored,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    _restore();
  }
  final AuthRepository _repo;

  Future<void> _restore() async {
    final user = await _repo.restore();
    state = state.copyWith(user: user, restored: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(user: user, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString().replaceFirst('Failure: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(restored: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});
