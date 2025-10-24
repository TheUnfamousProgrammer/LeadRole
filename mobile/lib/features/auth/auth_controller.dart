import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';
import 'auth_repository.dart';

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref)..restore();
});

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const AuthState());

  Future<void> restore() async {
    final repo = ref.read(authRepositoryProvider);
    final userId = await repo.getUserID();
    if (userId == null) return;
    try {
      final me = await repo.getUser(userId);
      if (me != null) state = AuthState(user: me);
    } catch (_) {}
  }

  Future<void> doSignup(String email, String password) async {
    state = state.copyWith(loading: true, error: '');
    try {
      final (token, user) = await ref
          .read(authRepositoryProvider)
          .signup(email, password);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email.trim());
      await prefs.setString('userId', user.id);
      state = AuthState(user: user, token: token);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> doLogin(String email, String password) async {
    state = state.copyWith(loading: true, error: '');
    try {
      final (token, user) = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email.trim());
      await prefs.setString('userId', user.id);
      state = AuthState(user: user, token: token);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).clearToken();
    state = const AuthState();
  }
}
