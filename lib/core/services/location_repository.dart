// lib/core/services/location_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationRepository {
  static const String _baseUrl = 'http://192.168.31.166:8000/api/v1';

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
