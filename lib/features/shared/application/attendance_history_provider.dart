import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/core/constants/api_config.dart';

class Attendance {
  final int id;
  final int userId;
  final String type;
  final String photoUrl;
  final double gpsLat;
  final double gpsLng;
  final DateTime timestamp;
  final bool confirmed;

  Attendance({
    required this.id,
    required this.userId,
    required this.type,
    required this.photoUrl,
    required this.gpsLat,
    required this.gpsLng,
    required this.timestamp,
    required this.confirmed,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'],
    userId: json['user_id'],
    type: json['type'],
    photoUrl: json['photo_url'],
    gpsLat: (json['gps_lat'] as num).toDouble(),
    gpsLng: (json['gps_lng'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    confirmed: json['confirmed'],
  );
}

final attendanceHistoryProvider = FutureProvider.family
    .autoDispose<List<Attendance>, int>((ref, userId) async {
      print('Cargando historial para userId: $userId');
      final token = ref.read(authNotifierProvider).token;
      print('Token: $token');
      if (token == null) throw Exception('No token found');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        final List<dynamic> data = jsonDecode(response.body);
        print('Asistencias cargadas: ${data.length}');
        return data.map((e) => Attendance.fromJson(e)).toList();
      } else {
        throw Exception('Error loading attendance history');
      }
    });
