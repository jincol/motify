import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:motify/core/constants/google_maps_config.dart';

class MotorizadoMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String motorizadoName;

  const MotorizadoMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    required this.motorizadoName,
  }) : super(key: key);

  @override
  State<MotorizadoMapWidget> createState() => _MotorizadoMapWidgetState();
}

class _MotorizadoMapWidgetState extends State<MotorizadoMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMarker();
  }

  void _initializeMarker() {
    final lat = widget.latitude ?? GoogleMapsConfig.defaultLatitude;
    final lng = widget.longitude ?? GoogleMapsConfig.defaultLongitude;

    _markers = {
      Marker(
        markerId: MarkerId('motorizado_location'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: widget.motorizadoName,
          snippet: 'Última ubicación conocida',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
  }

  @override
  void didUpdateWidget(MotorizadoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _initializeMarker();
      _animateToPosition();
    }
  }

  void _animateToPosition() {
    final lat = widget.latitude ?? GoogleMapsConfig.defaultLatitude;
    final lng = widget.longitude ?? GoogleMapsConfig.defaultLongitude;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        GoogleMapsConfig.defaultZoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.latitude ?? GoogleMapsConfig.defaultLatitude;
    final lng = widget.longitude ?? GoogleMapsConfig.defaultLongitude;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: GoogleMapsConfig.defaultZoom,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          if (widget.latitude == null || widget.longitude == null)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Ubicación no disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
