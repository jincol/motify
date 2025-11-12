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
    int? pedidoId,  // ✅ NUEVO: ID del pedido activo (opcional)
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
          // ignore
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
              if (pedidoId != null) 'pedido_id': pedidoId,  // ✅ Incluir solo si existe
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
                    if (pedidoId != null) 'pedido_id': pedidoId,  // ✅ Incluir en retry
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

  /// Obtener historial de ubicaciones de un usuario
  static Future<List<Map<String, dynamic>>> getLocationHistory({
    required int userId,
    required String token,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$_baseUrl/location/history/$userId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('❌ Error al obtener historial: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener historial de ubicaciones: $e');
      return [];
    }
  }

  /// Obtener ruta activa del pedido en curso
  static Future<List<Map<String, dynamic>>> getActiveRoute({
    required int userId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/location/active-route/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('❌ Error al obtener ruta activa: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener ruta activa: $e');
      return [];
    }
  }
}
