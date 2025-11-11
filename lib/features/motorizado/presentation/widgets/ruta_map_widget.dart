import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/location_repository.dart';

class RutaMapWidget extends StatefulWidget {
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  const RutaMapWidget({
    super.key,
    this.isFullscreen = false,
    this.onToggleFullscreen,
  });

  @override
  State<RutaMapWidget> createState() => _RutaMapWidgetState();
}

class _RutaMapWidgetState extends State<RutaMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _estadoRuta = 'Cargando ruta...';
  Timer? _refreshTimer;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Key única para forzar reconstrucción del mapa
  final UniqueKey _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    print('🗺️ RutaMapWidget initState - Iniciando widget de mapa');
    _checkPermissions();
    _loadRouteData();
    _startAutoRefresh();
  }

  Future<void> _checkPermissions() async {
    print('🔐 Verificando permisos de ubicación...');
    try {
      final permission = await Geolocator.checkPermission();
      print('   Estado actual: $permission');
      
      if (permission == LocationPermission.denied) {
        print('   ⚠️ Permiso denegado, solicitando...');
        final requested = await Geolocator.requestPermission();
        print('   Resultado solicitud: $requested');
      }
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('   GPS habilitado: $serviceEnabled');
    } catch (e) {
      print('   ❌ Error verificando permisos: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRouteData();
    });
  }

  Future<void> _loadRouteData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _storage.read(key: 'token'); // ✅ Clave correcta
      final userId = prefs.getInt('user_id');

      print('🔐 DEBUG Auth:');
      print('   Token existe: ${token != null}');
      print('   User ID: $userId');

      if (token == null || userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _estadoRuta = '❌ No hay token o user_id';
          });
        }
        return;
      }

      print('🔍 Obteniendo historial...');
      final locations = await LocationRepository.getLocationHistory(
        userId: userId,
        token: token,
      );
      print('📍 Ubicaciones recibidas: ${locations.length}');

      final enRutaLocations = locations.where((loc) {
        return loc['work_state'] == 'EN_RUTA';
      }).toList();

      print('🗺️ Ubicaciones EN_RUTA: ${enRutaLocations.length}');

      if (enRutaLocations.isEmpty) {
        await _showCurrentLocationOnly();
        return;
      }

      enRutaLocations.sort((a, b) {
        final timestampA = DateTime.parse(a['timestamp'] as String);
        final timestampB = DateTime.parse(b['timestamp'] as String);
        return timestampA.compareTo(timestampB);
      });

      final newMarkers = <Marker>{};
      final polylinePoints = <LatLng>[];

      for (var i = 0; i < enRutaLocations.length; i++) {
        final loc = enRutaLocations[i];
        final lat = loc['latitude'] as double;
        final lng = loc['longitude'] as double;
        final position = LatLng(lat, lng);

        polylinePoints.add(position);

        if (i == 0 || i == enRutaLocations.length - 1) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('point_$i'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: i == 0 ? 'Inicio' : 'Último punto',
                snippet: DateTime.parse(loc['timestamp'] as String)
                    .toLocal()
                    .toString()
                    .substring(11, 16),
              ),
            ),
          );
        }
      }

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: Colors.blue,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
          _polylines.clear();
          _polylines.add(polyline);
          _isLoading = false;
          _estadoRuta =
              'En ruta - ${enRutaLocations.length} puntos (${_calculateDistance(polylinePoints).toStringAsFixed(2)} km)';
        });
      }

      if (polylinePoints.isNotEmpty && _mapController != null && mounted) {
        _fitBounds(polylinePoints);
      }
    } catch (e, stackTrace) {
      print('❌ Error cargando ruta: ${e.runtimeType} - $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _estadoRuta = 'Error al cargar ruta';
        });
      }
    }
  }

  Future<void> _showCurrentLocationOnly() async {
    try {
      print('📍 Intentando obtener ubicación actual del GPS...');
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');

      final currentLocation = LatLng(position.latitude, position.longitude);

      print('🔧 Actualizando setState con marcador en: $currentLocation');
      
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: currentLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: const InfoWindow(
                title: 'Mi ubicación',
                snippet: 'Esperando ruta activa',
              ),
            ),
          );
          _polylines.clear();
          _isLoading = false;
          _estadoRuta = 'En espera - Ubicación actual';
        });
      }

      print('📹 Animando cámara a ubicación actual...');

      if (_mapController != null && mounted) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 16,
            ),
          ),
        );
      }

      print('✅ _showCurrentLocationOnly completado');
    } catch (e) {
      print('❌ Error obteniendo ubicación actual: ${e.runtimeType} - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _estadoRuta = 'Error al obtener ubicación';
        });
      }
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

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
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  double _calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (var i = 0; i < points.length - 1; i++) {
      totalDistance += _distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  double _distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 RutaMapWidget build() llamado');
    print('   _isLoading: $_isLoading');
    print('   _markers: ${_markers.length}');
    print('   _polylines: ${_polylines.length}');
    print('   _estadoRuta: $_estadoRuta');

    // Obtener tamaño de la pantalla
    final size = MediaQuery.of(context).size;
    print('📐 Dimensiones disponibles:');
    print('   Ancho: ${size.width}');
    print('   Alto: ${size.height}');

    // Usar la posición del primer marcador o una posición por defecto
    final initialPosition = _markers.isNotEmpty
        ? _markers.first.position
        : const LatLng(-12.09, -77.01); // Lima, Perú

    print('📍 Posición inicial del mapa: $initialPosition');

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          print('📏 Constraints del LayoutBuilder:');
          print('   maxWidth: ${constraints.maxWidth}');
          print('   maxHeight: ${constraints.maxHeight}');
          
          if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
            print('❌ ERROR: Constraints inválidos - El widget padre no tiene tamaño');
            return Container(
              color: Colors.red,
              child: const Center(
                child: Text(
                  'ERROR: Sin espacio disponible',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          
          return Stack(
          children: [
            // Mapa base - Ocupa TODO el espacio disponible
            Positioned.fill(
              child: Container(
                color: Colors.red.withOpacity(0.1), // Debug: fondo rojo tenue
                child: GoogleMap(
                  key: _mapKey, // Key única para forzar renderizado
                  onMapCreated: (GoogleMapController controller) {
                    print('🗺️ ✅ GoogleMap onMapCreated - Mapa creado exitosamente');
                    print('   Controller: ${controller.hashCode}');
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 15,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  mapToolbarEnabled: false,
                  onCameraMove: (CameraPosition position) {
                    print('📹 Cámara se movió a: ${position.target}');
                  },
                  onCameraIdle: () {
                    print('📹 Cámara detenida');
                  },
                  onTap: (LatLng position) {
                    print('👆 Tap en mapa: $position');
                  },
                ),
              ),
            ),

        // Overlay de loading
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Header con estado
        if (!widget.isFullscreen)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _polylines.isEmpty
                          ? Icons.location_searching
                          : Icons.route,
                      color: _polylines.isEmpty ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _estadoRuta,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Botón de pantalla completa
        if (widget.onToggleFullscreen != null)
          Positioned(
            top: widget.isFullscreen ? 16 : 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'fullscreen_btn',
              onPressed: widget.onToggleFullscreen,
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(
                widget.isFullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                color: Colors.blue,
              ),
            ),
          ),

        // Botón de recarga
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'refresh_btn',
            onPressed: _loadRouteData,
            backgroundColor: Colors.blue,
            elevation: 4,
            tooltip: 'Actualizar ruta',
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      ],
    );
        },
      ),
    );
  }
}
