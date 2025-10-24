import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/constants.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

class AuthRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBase));
  final _secure = const FlutterSecureStorage();

  Future<(String token, AuthUser user)> signup(
    String email,
    String password,
  ) async {
    final res = await _dio.post(
      '/api/auth/signup',
      data: {'email': email.trim(), 'password': password},
    );
    final data = res.data as Map<String, dynamic>;

    return (data['token'] as String, AuthUser.fromMap(data['user']));
  }

  Future<(String token, AuthUser user)> login(
    String email,
    String password,
  ) async {
    final res = await _dio.post(
      '/api/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    final data = res.data as Map<String, dynamic>;
    return (data['token'] as String, AuthUser.fromMap(data['user']));
  }

  Future<AuthUser?> getUser(String userID) async {
    final res = await _dio.get('/api/user/$userID');
    if (res.statusCode == 200) {
      return AuthUser.fromMap(res.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> hasPersona(String userId) async {
    try {
      final res = await _dio.get('/api/persona/get/$userId');
      return res.statusCode == 200;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }

  Future<String?> getUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    return userId;
  }

  Future<void> storeToken(String token) =>
      _secure.write(key: 'jwt', value: token);
  Future<String?> getStoredToken() => _secure.read(key: 'jwt');
  Future<void> clearToken() => _secure.delete(key: 'jwt');
}
