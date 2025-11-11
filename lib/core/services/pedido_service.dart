import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:motify/core/constants/api_config.dart';
import '../models/pedido_model.dart';

class PedidoService {
  static final String _baseUrl = ApiConfig.baseApiUrl;
  static const _storage = FlutterSecureStorage();


  static Future<ParadaModel?> crearYConfirmarParada({
      required int pedidoId,
      required String tipo,
      required String direccion,
      required String fotoUrl,
      required double gpsLat,
      required double gpsLng,
      required String fechaHora,
      String? notas,
    }) async {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseApiUrl}/stops/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': pedidoId,
          'type': tipo,
          'address': direccion,
          'photo_url': fotoUrl,
          'latitude': gpsLat,
          'longitude': gpsLng,
          'timestamp': fechaHora,
          'notes': notas,
        }),
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> rawResponse = jsonDecode(response.body);
        // Normalizar campos del backend (inglés) al formato del modelo (español)
        final normalizedResponse = {
          'id_parada': rawResponse['id'],
          'pedido_id': rawResponse['order_id'],
          'tipo': rawResponse['type'],
          'direccion': rawResponse['address'],
          'orden': rawResponse['stop_order'],
          'foto_url': rawResponse['photo_url'],
          'gps_lat': rawResponse['latitude'],
          'gps_lng': rawResponse['longitude'],
          'fecha_hora': rawResponse['timestamp'],
          'confirmado': rawResponse['confirmed'] ?? true,
          'notas': rawResponse['notes'],
        };
        return ParadaModel.fromJson(normalizedResponse);
      } else {
        print('❌ Error al crear parada: ${response.statusCode} - ${response.body}');
        return null;
      }
    }

  /// Obtener pedidos del motorizado
  static Future<List<PedidoModel>> getPedidosMotorizado() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/orders/mine'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // DEBUG: Imprimir la respuesta del backend
        print('🔍 DEBUG: Pedidos recibidos del backend:');
        print(jsonEncode(data));

        List<PedidoModel> pedidos = data.map((orderJsonRaw) {
          final Map<String, dynamic> orderJson = Map<String, dynamic>.from(
            orderJsonRaw,
          );

          // Obtener array de paradas desde posibles keys: 'paradas' (español) o 'stops' (backend)
          final rawStops =
              (orderJson['paradas'] ?? orderJson['stops'] ?? [])
                  as List<dynamic>;

          // Transformar cada parada al formato que espera ParadaModel.fromJson
          final normalizedStops = rawStops.map((sRaw) {
            final Map<String, dynamic> s = Map<String, dynamic>.from(sRaw);
            return {
              'id_parada': s['id'] ?? s['id_parada'],
              'pedido_id':
                  s['order_id'] ??
                  s['pedido_id'] ??
                  orderJson['id'] ??
                  orderJson['id_pedido'],
              'tipo': s['type'] ?? s['tipo'],
              'direccion': s['address'] ?? s['direccion'],
              'orden': s['stop_order'] ?? s['orden'],
              'foto_url': s['photo_url'] ?? s['foto_url'],
              'gps_lat': s['latitude'] ?? s['gps_lat'],
              'gps_lng': s['longitude'] ?? s['gps_lng'],
              'fecha_hora': s['timestamp'] ?? s['fecha_hora'],
              'confirmado': s['confirmed'] ?? s['confirmado'] ?? false,
              'notas': s['notes'] ?? s['notas'],
            };
          }).toList();

          // Colocamos/reescribimos la key `paradas` para que PedidoModel la consuma
          orderJson['paradas'] = normalizedStops;
          return PedidoModel.fromJson(orderJson);
        }).toList();

        return pedidos;
      } else {
        print(
          '❌ Error al obtener pedidos: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('❌ Error en getPedidosMotorizado: $e');
      rethrow;
    }
  }

  /// Confirmar parada (recojo o entrega) con foto (MOCK temporal)
  static Future<bool> confirmarParada({
    required int paradaId,
    required String fotoUrl,
    required double lat,
    required double lng,
    String? notas,
    String? direccionEntrega, // Nuevo: dirección de entrega (solo para recojo)
    double? latEntrega, // Nuevo: latitud de entrega
    double? lngEntrega, // Nuevo: longitud de entrega
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
            // Uri.parse('${ApiConfig.baseApiUrl}/paradas/$paradaId/confirmar'),
            Uri.parse('${ApiConfig.baseApiUrl}/stops/$paradaId/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'photo_url': fotoUrl,
          'latitude': lat,
          'longitude': lng,
          'notes': notas,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Parada $paradaId confirmada');
        return true;
      } else {
        print('❌ Error al confirmar parada: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en confirmarParada: $e');
      return false;
    }
    
  }

  /// Crear nuevo pedido
  static Future<bool> crearPedido({
    required String titulo,
    required String nombreRemitente,
    String? telefono,
    String? direccionRecojo,
    String? direccionEntrega,
    String? descripcion,
    String? instrucciones,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      // Construir body con las keys en inglés que espera el backend
      final body = jsonEncode({
        'title': titulo,
        'sender_name': nombreRemitente,
        if (telefono != null) 'sender_phone': telefono,
        if (descripcion != null) 'description': descripcion,
        if (instrucciones != null) 'instructions': instrucciones,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Pedido creado (backend)');
        return true;
      } else {
        print(
          '❌ Error al crear pedido: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error en crearPedido: $e');
      return false;
    }
  }
}


// -------------------------------------------------------------------------------


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/pedido_model.dart';

// class PedidoService {
//   static const String _baseUrl = 'http://192.168.31.166:8000/api/v1';
//   static const _storage = FlutterSecureStorage();

//   /// Obtener pedidos del motorizado
//   static Future<List<PedidoModel>> getPedidosMotorizado() async {
//     try {
//       final token = await _storage.read(key: 'token');
//       if (token == null) throw Exception('No token found');

//       final response = await http.get(
//         Uri.parse('$_baseUrl/pedidos/mis-pedidos'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         return data.map((p) => PedidoModel.fromJson(p)).toList();
//       } else {
//         throw Exception('Error al obtener pedidos: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error en getPedidosMotorizado: $e');
//       rethrow;
//     }
//   }

            
//   static Future<bool> confirmarParada({
//     required int paradaId,
//     required String fotoUrl,
//     required double lat,
//     required double lng,
//     String? notas,
//   }) async {
//     try {
//       final token = await _storage.read(key: 'token');
//       if (token == null) throw Exception('No token found');

//       final response = await http.post(
//         Uri.parse('$_baseUrl/paradas/$paradaId/confirmar'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'foto_url': fotoUrl,
//           'gps_lat': lat,
//           'gps_lng': lng,
//           'notas': notas,
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('✅ Parada $paradaId confirmada');
//         return true;
//       } else {
//         print('❌ Error al confirmar parada: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       print('❌ Error en confirmarParada: $e');
//       return false;
//     }
//   }
// }
