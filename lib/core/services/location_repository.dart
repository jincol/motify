// lib/core/services/location_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:motify/core/services/auth_repository.dart';
import 'package:motify/core/constants/api_config.dart';

class LocationRepository {
  static final String _baseUrl = ApiConfig.baseUrl;

  /// Enviar ubicación al backend
  static Future<bool> sendLocation({
    required int userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String workState,
    required double speed,
    required double heading,
    required String token,
  }) async {
    try {
      // Proactive refresh: si el token expira en menos de 60s, intentar refresh antes de enviar
      try {
        int _getExpFromToken(String t) {
          String _normalize(String str) {
            final mod = str.length % 4;
            if (mod == 2) return str + '==';
            if (mod == 3) return str + '=';
            if (mod == 1) return str + '===';
            return str;
          }

          final parts = t.split('.');
          if (parts.length < 2) return 0;
          final payload = parts[1];
          final normalized = _normalize(
            payload.replaceAll('-', '+').replaceAll('_', '/'),
          );
          final decoded = jsonDecode(
            String.fromCharCodes(base64.decode(normalized)),
          );
          return decoded['exp'] ?? 0;
        }

        final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        try {
          final exp = _getExpFromToken(token);
          if (exp > 0 && exp < nowSec + 60) {
            print(
              '🔄 Token expira pronto (exp=$exp), intentando refresh proactivo',
            );
            final newToken = await AuthRepository.refreshAccessToken();
            if (newToken != null) token = newToken;
          }
        } catch (e) {
          // si falla la decodificación, no bloqueamos el envío
        }
      } catch (e) {
        // ignore
      }

      final url = Uri.parse('$_baseUrl/location/update');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': accuracy,
              'work_state': workState,
              'speed': speed,
              'heading': heading,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Ubicación enviada correctamente');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ Error 401: ${response.body} - intentando refresh token');
        // Intentar refresh
        final newToken = await AuthRepository.refreshAccessToken();
        if (newToken != null) {
          try {
            final retry = await http
                .post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $newToken',
                  },
                  body: jsonEncode({
                    'user_id': userId,
                    'latitude': latitude,
                    'longitude': longitude,
                    'accuracy': accuracy,
                    'work_state': workState,
                    'speed': speed,
                    'heading': heading,
                  }),
                )
                .timeout(const Duration(seconds: 10));

            if (retry.statusCode == 200 || retry.statusCode == 201) {
              print(
                '✅ Ubicación enviada correctamente (retry con token refresh)',
              );
              return true;
            } else {
              print('❌ Retry falló: ${retry.statusCode}: ${retry.body}');
              return false;
            }
          } catch (e) {
            print('❌ Error en retry after refresh: $e');
            return false;
          }
        }
        return false;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error al enviar ubicación: $e');
      return false;
    }
  }
}
