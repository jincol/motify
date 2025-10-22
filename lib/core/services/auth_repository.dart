import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motify/core/constants/api_config.dart';

class AuthRepository {
  static final String _baseUrl = ApiConfig.baseApiUrl;
  static const _secure = FlutterSecureStorage();

  /// Guarda access + refresh tokens en secure storage.
  /// Si alsoSaveToPrefs es true, también actualiza SharedPreferences 'auth_token'.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool alsoSaveToPrefs = false,
  }) async {
    await _secure.write(key: 'token', value: accessToken);
    await _secure.write(key: 'refresh_token', value: refreshToken);
    if (alsoSaveToPrefs) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);
      } catch (_) {}
    }
  }

  static Future<String?> readAccessToken() async {
    return await _secure.read(key: 'token');
  }

  static Future<String?> readRefreshToken() async {
    return await _secure.read(key: 'refresh_token');
  }

  static Future<String?> refreshAccessToken() async {
    final refresh = await readRefreshToken();
    if (refresh == null) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;
        if (newAccess != null) {
          await _secure.write(key: 'token', value: newAccess);
          if (newRefresh != null) {
            await _secure.write(key: 'refresh_token', value: newRefresh);
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', newAccess);
          } catch (_) {}
          return newAccess;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
