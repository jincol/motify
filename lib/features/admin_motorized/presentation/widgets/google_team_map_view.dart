import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:motify/core/constants/google_maps_config.dart';
import 'package:motify/core/models/user_location_detail.dart';
import 'package:motify/core/providers/group_locations_provider.dart';
import 'package:motify/features/admin_motorized/presentation/widgets/order_selection_bottom_sheet.dart';

class GoogleTeamMapView extends ConsumerStatefulWidget {
  const GoogleTeamMapView({super.key});

  @override
  ConsumerState<GoogleTeamMapView> createState() => _GoogleTeamMapViewState();
}

class _GoogleTeamMapViewState extends ConsumerState<GoogleTeamMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Variables para la ruta seleccionada
  Set<Marker> _routeMarkers = {}; // Markers de paradas (pickup/delivery)
  Set<Polyline> _routePolylines = {}; // Polyline de la ruta
  int? _selectedUserId; // ID del motorizado cuya ruta se está mostrando
  int? _selectedOrderId; // ID del pedido cuya ruta se está mostrando

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(groupLocationsProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 350,
        child: Stack(
          children: [
            locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return _buildEmptyState();
                }

                // Actualizar marcadores y rutas
                _updateMapData(locations);

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      GoogleMapsConfig.defaultLatitude,
                      GoogleMapsConfig.defaultLongitude,
                    ),
                    zoom: 12.0,
                  ),
                  markers: {..._markers, ..._routeMarkers}, // ✅ Combinar ambos sets
                  polylines: {..._polylines, ..._routePolylines}, // ✅ Combinar ambos sets
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitBoundsToMarkers(locations);
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
            
            // Controles sobre el mapa
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  // Botón para recentrar el mapa
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.center_focus_strong, color: Colors.orange),
                      onPressed: () {
                        final locations = ref.read(groupLocationsProvider).value;
                        if (locations != null && locations.isNotEmpty) {
                          _fitBoundsToMarkers(locations);
                        }
                      },
                      tooltip: 'Centrar mapa',
                    ),
                  ),
                ],
              ),
            ),

            // Botón flotante para ocultar ruta (solo visible cuando hay ruta activa)
            if (_selectedOrderId != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _clearRoute,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.close, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Ocultar ruta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Indicador de actualización
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'En vivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMapData(List<UserLocationDetail> locations) {
    final newMarkers = <Marker>{};

    for (final location in locations) {
      final position = LatLng(location.latitude, location.longitude);
      
      newMarkers.add(
        Marker(
          markerId: MarkerId('user_${location.userId}'),
          position: position,
          icon: _getMarkerIcon(location.workState),
          infoWindow: InfoWindow(
            title: '🏍️ ${location.displayName}',
            snippet: _getStatusText(location.workState),
          ),
          // ⭐ CLICK EN MARCADOR: Mostrar bottom sheet con pedidos
          onTap: () {
            _showOrdersBottomSheet(location);
          },
        ),
      );
    }

    // ✅ MANTENER markers de ruta si existe una seleccionada
    // NO volver a llamar _displayRouteForOrder() aquí (causa bucle infinito)
    if (_routeMarkers.isNotEmpty) {
      newMarkers.addAll(_routeMarkers);
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  /// Mostrar bottom sheet con lista de pedidos del motorizado
  void _showOrdersBottomSheet(UserLocationDetail location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => OrderSelectionBottomSheet(
        courierId: location.userId,
        courierName: location.displayName,
        onOrderSelected: (orderId) {
          _displayRouteForOrder(location.userId, orderId);
        },
      ),
    );
  }

  /// Mostrar la ruta de un pedido específico en el mapa
  Future<void> _displayRouteForOrder(int userId, int orderId) async {
    try {
      print('🗺️ Mostrando ruta del pedido $orderId del usuario $userId...');
      
      // ✅ Usar el nuevo provider que obtiene por order_id
      final routeData = await ref.read(routeByOrderProvider(orderId).future);
      
      final gpsPoints = routeData['gps_points'] as List? ?? [];
      final stops = routeData['stops'] as List? ?? [];
      
      // ✅ Backend ya filtra por order_id, no necesitamos filtrar aquí
      if (gpsPoints.isEmpty && stops.isEmpty) {
        print('⚠️ No hay datos de ruta para este pedido');
        return;
      }

      // 1. Dibujar polyline con los puntos GPS del pedido
      final polylinePoints = <LatLng>[];
      for (final point in gpsPoints) {
        final lat = (point['latitude'] as num).toDouble();
        final lng = (point['longitude'] as num).toDouble();
        polylinePoints.add(LatLng(lat, lng));
      }

      // 2. Crear markers y polylines de la RUTA (separados de los motorizados)
      final routeMarkers = <Marker>{};
      final routePolylines = <Polyline>{};

      if (polylinePoints.length >= 2) {
        routePolylines.add(
          Polyline(
            polylineId: PolylineId('route_$orderId'),
            points: polylinePoints,
            color: Colors.blue,
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }

      // 3. Agregar markers para las paradas (pickup/delivery) del pedido
      for (final stop in stops) {
        if (stop['order_id'] != orderId) continue;
        
        final lat = stop['latitude'];
        final lng = stop['longitude'];
        
        if (lat == null || lng == null) continue;
        
        final stopType = stop['type'] as String;
        final isPickup = stopType == 'pickup';
        final confirmed = stop['confirmed'] as bool? ?? false;
        
        routeMarkers.add(
          Marker(
            markerId: MarkerId('stop_${stop['id']}'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            icon: isPickup
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: isPickup ? '📦 Recojo' : '🎯 Entrega',
              snippet: '${stop['address'] ?? 'Sin dirección'}\n${confirmed ? '✅ Confirmado' : '⏳ Pendiente'}',
            ),
          ),
        );
      }
      
      // 4. Agregar marcador de INICIO de la ruta (primer punto GPS)
      if (polylinePoints.isNotEmpty) {
        routeMarkers.add(
          Marker(
            markerId: MarkerId('route_start_$orderId'),
            position: polylinePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: '▶️ INICIO',
              snippet: 'Primer punto GPS',
            ),
          ),
        );
      }
      
      // 5. Agregar marcador de FIN de la ruta (último punto GPS) - solo si está finalizado
      final orderInfo = routeData['order'] as Map<String, dynamic>?;
      final orderStatus = orderInfo?['status'] as String?;
      
      if (polylinePoints.length > 1 && orderStatus == 'finished') {
        routeMarkers.add(
          Marker(
            markerId: MarkerId('route_end_$orderId'),
            position: polylinePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '🏁 FIN',
              snippet: 'Último punto GPS',
            ),
          ),
        );
      }
      
      if (mounted) {
        setState(() {
          _selectedUserId = userId;
          _selectedOrderId = orderId;
          _routeMarkers = routeMarkers; // ✅ Guardar en variables separadas
          _routePolylines = routePolylines; // ✅ Guardar en variables separadas
        });

        // Ajustar cámara para mostrar toda la ruta
        if (polylinePoints.length >= 2 && _mapController != null) {
          _fitBoundsToPoints(polylinePoints);
        }
      }
      
      print('✅ Ruta del pedido $orderId mostrada correctamente');
    } catch (e) {
      print('❌ Error mostrando ruta del pedido $orderId: $e');
    }
  }

  /// Ajustar cámara para mostrar todos los puntos de la ruta
  void _fitBoundsToPoints(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points[0], 15.0),
      );
      return;
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  /// Ocultar la ruta actualmente visible
  void _clearRoute() {
    if (mounted) {
      setState(() {
        _selectedUserId = null;
        _selectedOrderId = null;
        _routePolylines.clear(); // ✅ Limpiar polylines de ruta
        _routeMarkers.clear(); // ✅ Limpiar markers de ruta
      });
    }
  }

  BitmapDescriptor _getMarkerIcon(String workState) {
    // 🏍️ Usar iconos de moto con diferentes colores según el estado
    switch (workState.toUpperCase()) {
      case 'EN_RUTA':
        // Verde: En ruta activa
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'JORNADA_ACTIVA':
        // Naranja: Jornada activa pero sin pedido
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'INACTIVO':
      default:
        // Gris: Inactivo
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  String _getStatusText(String workState) {
    switch (workState.toUpperCase()) {
      case 'EN_RUTA':
        return '🚚 En Ruta';
      case 'JORNADA_ACTIVA':
        return '✅ Jornada Activa';
      case 'INACTIVO':
      default:
        return '⏸️ Inactivo';
    }
  }

  void _fitBoundsToMarkers(List<UserLocationDetail> locations) {
    if (locations.isEmpty || _mapController == null) return;

    if (locations.length == 1) {
      // Si solo hay un motorizado, centrar en él
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locations[0].latitude, locations[0].longitude),
          14.0,
        ),
      );
      return;
    }

    // Calcular bounds para incluir todos los marcadores
    double minLat = locations[0].latitude;
    double maxLat = locations[0].latitude;
    double minLng = locations[0].longitude;
    double maxLng = locations[0].longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Cargando ubicaciones...',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.black38),
            SizedBox(height: 16),
            Text(
              'No hay motorizados activos',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar mapa',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
