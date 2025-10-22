// lib/core/services/pedido_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pedido_model.dart';

class PedidoService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const _storage = FlutterSecureStorage();

  /// Obtener pedidos del motorizado (MOCK temporal)
  static Future<List<PedidoModel>> getPedidosMotorizado() async {
    // TODO: Descomentar cuando el backend esté listo
    /*
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos/mis-pedidos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((p) => PedidoModel.fromJson(p)).toList();
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getPedidosMotorizado: $e');
      rethrow;
    }
    */

    // DATOS MOCK TEMPORALES
    await Future.delayed(const Duration(milliseconds: 500)); // Simular latencia

    return [
      PedidoModel(
        id: 1,
        codigoPedido: 'PED-2025-001',
        motorizadoId: 131,
        titulo: 'Entrega Documentos Oficina A&B',
        nombreRemitente: 'Almacén Central',
        telefono: '987654321',
        descripcion: 'Paquete con documentos y papelería',
        instrucciones: 'Entregar en recepción del 3er piso',
        estado: 'pendiente',
        paradas: [
          ParadaModel(
            id: 1,
            pedidoId: 1,
            tipo: 'recojo',
            direccion: 'Av. Javier Prado 123, San Isidro',
            orden: 1,
            confirmado: false,
          ),
          ParadaModel(
            id: 2,
            pedidoId: 1,
            tipo: 'entrega',
            direccion: 'Calle Las Begonias 456, San Isidro',
            orden: 2,
            confirmado: false,
          ),
        ],
        fechaCreacion: DateTime.now().subtract(const Duration(hours: 2)),
        fechaAsignacion: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      PedidoModel(
        id: 2,
        codigoPedido: 'PED-2025-002',
        motorizadoId: 131,
        titulo: 'Recojo Documentos Cliente X',
        nombreRemitente: 'Cliente X SAC',
        telefono: '912345678',
        descripcion: 'Documentos confidenciales',
        instrucciones: 'Requiere firma del receptor',
        estado: 'pendiente',
        paradas: [
          ParadaModel(
            id: 3,
            pedidoId: 2,
            tipo: 'recojo',
            direccion: 'Jr. Lampa 890, Cercado de Lima',
            orden: 1,
            confirmado: false,
          ),
          ParadaModel(
            id: 4,
            pedidoId: 2,
            tipo: 'entrega',
            direccion: 'Av. Arequipa 1200, Miraflores',
            orden: 2,
            confirmado: false,
          ),
        ],
        fechaCreacion: DateTime.now().subtract(const Duration(hours: 3)),
        fechaAsignacion: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      PedidoModel(
        id: 3,
        codigoPedido: 'PED-2025-003',
        motorizadoId: 131,
        titulo: 'Entrega Urgente Zona Financiera',
        nombreRemitente: 'Sucursal Sur',
        telefono: '998877665',
        descripcion: 'Paquete urgente',
        instrucciones: 'Entregar antes de las 6 PM',
        estado: 'pendiente',
        paradas: [
          ParadaModel(
            id: 5,
            pedidoId: 3,
            tipo: 'recojo',
            direccion: 'Av. Benavides 2345, Surco',
            orden: 1,
            confirmado: false,
          ),
          ParadaModel(
            id: 6,
            pedidoId: 3,
            tipo: 'entrega',
            direccion: 'Paseo de la República 5678, La Victoria',
            orden: 2,
            confirmado: false,
          ),
        ],
        fechaCreacion: DateTime.now().subtract(const Duration(minutes: 45)),
        fechaAsignacion: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ];
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
    // TODO: Descomentar cuando el backend esté listo
    /*
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/paradas/$paradaId/confirmar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'foto_url': fotoUrl,
          'gps_lat': lat,
          'gps_lng': lng,
          'notas': notas,
          'direccion_entrega': direccionEntrega,
          'lat_entrega': latEntrega,
          'lng_entrega': lngEntrega,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Parada $paradaId confirmada');
        return true;
      } else {
        print('❌ Error al confirmar parada: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error en confirmarParada: $e');
      return false;
    }
    */

    // MOCK TEMPORAL - Simular confirmación exitosa
    await Future.delayed(const Duration(seconds: 1));
    print('✅ [MOCK] Parada $paradaId confirmada');
    print('   Foto: $fotoUrl');
    print('   GPS: $lat, $lng');
    if (notas != null) print('   Notas: $notas');
    if (direccionEntrega != null) {
      print('   📍 Dirección de entrega: $direccionEntrega');
      print('   📍 Coordenadas entrega: $latEntrega, $lngEntrega');
    }
    return true;
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
    // TODO: Descomentar cuando el backend esté listo
    /*
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/pedidos/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titulo': titulo,
          'nombre_remitente': nombreRemitente,
          'telefono_remitente': telefono,
          'direccion_recojo': direccionRecojo,
          'direccion_entrega': direccionEntrega,
          'descripcion': descripcion,
          'instrucciones': instrucciones,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Pedido creado');
        return true;
      } else {
        print('❌ Error al crear pedido: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error en crearPedido: $e');
      return false;
    }
    */

    // MOCK TEMPORAL - Simular creación exitosa
    await Future.delayed(const Duration(seconds: 2));
    print('✅ [MOCK] Pedido creado');
    print('   Título: $titulo');
    print('   Remitente: $nombreRemitente');
    print('   Teléfono: $telefono');
    print('   Recojo: $direccionRecojo');
    print('   Entrega: $direccionEntrega');
    print('   Descripción: $descripcion');
    print('   Instrucciones: $instrucciones');
    return true;
  }
}


// -------------------------------------------------------------------------------


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/pedido_model.dart';

// class PedidoService {
//   static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
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

//   /// Confirmar parada (recojo o entrega) con foto
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
