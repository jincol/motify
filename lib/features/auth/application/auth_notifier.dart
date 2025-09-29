import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _baseUrl = 'http://192.168.31.166:8000/api/v1/auth/token';
  final _storage = const FlutterSecureStorage();
  AuthNotifier() : super(AuthState(authStatus: AuthStatus.unknown)) {
    Future.delayed(const Duration(seconds: 1), () {
      state = AuthState(authStatus: AuthStatus.unauthenticated);
    });
  }
  Future<void> login(String username, String password) async {
    state = AuthState(authStatus: AuthStatus.loading);
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=password&username=$username&password=$password',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await _storage.write(key: 'token', value: token);

        final meResponse = await http.get(
          Uri.parse('http://192.168.31.166:8000/api/v1/users/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body);
          final role = meData['role'];
          final workState = meData['work_state'];
          state = AuthState(
            authStatus: AuthStatus.authenticated,
            role: role,
            workState: workState,
            token: token,
          );
        } else {
          state = AuthState(authStatus: AuthStatus.error);
        }
      } else {
        state = AuthState(authStatus: AuthStatus.error);
      }
    } catch (e) {
      state = AuthState(authStatus: AuthStatus.error);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    state = AuthState(authStatus: AuthStatus.unauthenticated);
  }

  Future<void> fetchMe() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    final meResponse = await http.get(
      Uri.parse('http://192.168.31.166:8000/api/v1/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (meResponse.statusCode == 200) {
      final meData = jsonDecode(meResponse.body);
      final role = meData['role'];
      final workState = meData['work_state'];
      state = AuthState(
        authStatus: AuthStatus.authenticated,
        role: role,
        workState: workState,
        token: token,
      );
    }
  }

  //change new
  void resetState() {
    state = AuthState(authStatus: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier();
});
