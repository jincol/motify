import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:motify/core/constants/google_maps_config.dart';

class GeocodingService {
  // Convertir coordenadas a dirección
  static Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${GoogleMapsConfig.serverApiKey}',
      );

      print('🗺️ GEOCODING REQUEST');
      print('   URL: $url');
      print('   Coordenadas: $latitude, $longitude');

      final response = await http.get(url);

      print('🗺️ GEOCODING RESPONSE');
      print('   Status Code: ${response.statusCode}');
      print(
        '   Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('   API Status: ${data['status']}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          print('✅ DIRECCIÓN OBTENIDA: $address');
          return address;
        } else {
          print('❌ GEOCODING FALLÓ');
          print('   Status: ${data['status']}');
          print('   Error: ${data['error_message'] ?? 'Sin mensaje de error'}');
        }
      } else {
        print('❌ HTTP ERROR: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('❌ EXCEPCIÓN EN GEOCODING: $e');
      return null;
    }
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress({
    required String address,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=${GoogleMapsConfig.serverApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {'latitude': location['lat'], 'longitude': location['lng']};
        }
      }

      return null;
    } catch (e) {
      print('Error en geocoding: $e');
      return null;
    }
  }
}
