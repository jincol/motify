import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:motify/core/constants/api_config.dart';
import 'package:motify/core/models/user_location_detail.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';

/// Provider para obtener las ubicaciones de todos los usuarios de un grupo
final groupLocationsProvider = StreamProvider.autoDispose<List<UserLocationDetail>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.token;
  
  // Para admins, su propio userId es el grupo_id
  // Para motorizados, usan su grupo_id
  final grupoId = authState.grupoId ?? authState.userId;

  if (token == null || grupoId == null) {
    throw Exception('No hay autenticación o grupo asignado');
  }

  // Función auxiliar para obtener ubicaciones
  Future<List<UserLocationDetail>> fetchLocations() async {
    try {
      print('🔄 Actualizando ubicaciones del grupo $grupoId (userId: ${authState.userId})...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/location/group/$grupoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final locations = data
            .map((json) => UserLocationDetail.fromJson(json))
            .toList();
        
        print('✅ Ubicaciones obtenidas: ${locations.length}');
        return locations;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener ubicaciones del grupo');
      }
    } catch (e) {
      print('❌ Error en groupLocationsProvider: $e');
      rethrow;
    }
  }

  // Stream que emite ubicaciones inmediatamente y luego cada 60 segundos
  final controller = StreamController<List<UserLocationDetail>>();
  
  // Primera petición inmediata
  fetchLocations().then((locations) {
    controller.add(locations);
  }).catchError((error) {
    controller.addError(error);
  });
  
  // Peticiones periódicas cada 60 segundos
  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    fetchLocations().then((locations) {
      if (!controller.isClosed) {
        controller.add(locations);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });
  });
  
  // Cleanup cuando el provider se dispose
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  
  return controller.stream;
});

/// Provider para obtener la ruta activa de un motorizado específico
final activeRouteProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, int>(
  (ref, userId) async {
    final authState = ref.watch(authNotifierProvider);
    final token = authState.token;

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    try {
      print('🔍 Obteniendo ruta activa del usuario $userId...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/location/active-route/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final locations = data
            .map((item) => item as Map<String, dynamic>)
            .toList();
        
        print('✅ Ruta activa obtenida: ${locations.length} puntos');
        return locations;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error obteniendo ruta activa: $e');
      return [];
    }
  },
);

/// Provider para obtener la ruta activa CON las paradas (stops)
final activeRouteWithStopsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, int>(
  (ref, userId) async {
    final authState = ref.watch(authNotifierProvider);
    final token = authState.token;

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    try {
      print('🔍 Obteniendo ruta con stops del usuario $userId...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/location/active-route-with-stops/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final stopsCount = (data['stops'] as List?)?.length ?? 0;
        final gpsCount = (data['gps_points'] as List?)?.length ?? 0;
        
        print('✅ Ruta con stops obtenida: $stopsCount paradas, $gpsCount puntos GPS');
        return data;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'order': null,
          'stops': [],
          'gps_points': [],
        };
      }
    } catch (e) {
      print('❌ Error obteniendo ruta con stops: $e');
      return {
        'order': null,
        'stops': [],
        'gps_points': [],
      };
    }
  },
);

/// Provider para obtener todos los pedidos del día de un motorizado
final todayOrdersProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, int>(
  (ref, courierId) async {
    final authState = ref.watch(authNotifierProvider);
    final token = authState.token;

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    try {
      print('📅 Obteniendo pedidos del día del motorizado $courierId...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/courier/$courierId/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final orders = data.map((item) => item as Map<String, dynamic>).toList();
        
        print('✅ Pedidos del día obtenidos: ${orders.length} pedidos');
        return orders;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error obteniendo pedidos del día: $e');
      return [];
    }
  },
);

/// Provider para obtener la ruta de un pedido específico (por order_id)
final routeByOrderProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, int>(
  (ref, orderId) async {
    final authState = ref.watch(authNotifierProvider);
    final token = authState.token;

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    try {
      print('🗺️ Obteniendo ruta del pedido $orderId...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/location/route-by-order/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        final gpsPoints = data['gps_points'] as List? ?? [];
        final stops = data['stops'] as List? ?? [];
        
        print('✅ Ruta del pedido $orderId obtenida: ${stops.length} paradas, ${gpsPoints.length} puntos GPS');
        
        return data;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'order': null,
          'stops': [],
          'gps_points': [],
        };
      }
    } catch (e) {
      print('❌ Error obteniendo ruta del pedido $orderId: $e');
      return {
        'order': null,
        'stops': [],
        'gps_points': [],
      };
    }
  },
);
