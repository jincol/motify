import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:motify/core/services/photo_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AttendanceService {
  static const String _attendanceUrl =
      'http://192.168.31.166:8000/api/v1/attendance/check-in';
  static final _storage = const FlutterSecureStorage();

  static Future<void> marcarAsistencia({
    required BuildContext context,
    required String tipo,
    required VoidCallback onSuccess,
  }) async {
    try {
      if (await Permission.camera.request().isDenied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado.')),
        );
        return;
      }
      if (await Permission.locationWhenInUse.request().isDenied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }

      //Tomar foto
      final file = await PhotoService.takePhoto();
      if (file == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes tomar una foto para marcar asistencia.'),
          ),
        );
        return;
      }

      //Obtener ubicación
      final position = await Geolocator.getCurrentPosition();
      final lat = position.latitude;
      final lng = position.longitude;

      //  Subir foto y obtener URL
      final photoUrl = await PhotoService.uploadPhoto(file);

      // Obtener token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró sesión activa.')),
        );
        return;
      }

      // endpoint asistencia
      final response = await http.post(
        Uri.parse(_attendanceUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': tipo,
          'photo_url': photoUrl,
          'gps_lat': lat,
          'gps_lng': lng,
        }),
      );

      if (!context.mounted) return;
      if (response.statusCode == 200) {
        print('onSuccess ejecutado - asistencia registrada');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencia registrada correctamente.')),
        );
        onSuccess();
      } else {
        final msg =
            _parseError(response.body) ?? 'Error al registrar asistencia.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  static String? _parseError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return null;
  }
}
