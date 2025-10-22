import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_state.dart';
import 'dart:convert';
import 'package:motify/core/services/auth_repository.dart';
import 'dart:developer' as developer;
import 'package:motify/core/constants/api_config.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  static final String _baseUrl = '${ApiConfig.baseApiUrl}/auth/token';
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
        final refresh = data['refresh_token'];
        try {
          await AuthRepository.saveTokens(
            accessToken: token,
            refreshToken: refresh ?? '',
            alsoSaveToPrefs: true,
          );
        } catch (_) {
          await _storage.write(key: 'token', value: token);
          if (refresh != null) {
            await _storage.write(key: 'refresh_token', value: refresh);
          }
        }

        final meResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body);
          final role = meData['role'];
          final workState = meData['work_state'];
          final userId = meData['id'];
          state = AuthState(
            authStatus: AuthStatus.authenticated,
            role: role,
            workState: workState,
            token: token,
            userId: userId,
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
    // Borrar token seguro
    await _storage.delete(key: 'token');

    // Limpiar SharedPreferences que pueda usar el background service
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('auth_token');
      await prefs.remove('work_state');
      await prefs.remove('tracking_interval_seconds');
      await prefs.remove('last_location_sent');
    } catch (e) {
      // no bloquear logout si falla limpiar prefs
      developer.log(
        'Error limpiando SharedPreferences en logout: $e',
        name: 'auth_notifier',
      );
    }

    state = AuthState(authStatus: AuthStatus.unauthenticated);
  }

  Future<void> fetchMe() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    final meResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (meResponse.statusCode == 200) {
      final meData = jsonDecode(meResponse.body);
      final userId = meData['id'];
      final role = meData['role'];
      final workState = meData['work_state'];
      state = AuthState(
        authStatus: AuthStatus.authenticated,
        role: role,
        workState: workState,
        token: token,
        userId: userId,
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
