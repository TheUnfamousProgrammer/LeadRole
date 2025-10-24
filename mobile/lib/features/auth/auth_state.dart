import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String id;
  final String email;
  const AuthUser({required this.id, required this.email});

  factory AuthUser.fromMap(Map<String, dynamic> m) =>
      AuthUser(id: m['id'] as String, email: m['email'] as String);
}

@immutable
class AuthState {
  final AuthUser? user;
  final String? token;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.token, this.loading = false, this.error});

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? loading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  bool get isAuthed => user != null && token != null;
}
