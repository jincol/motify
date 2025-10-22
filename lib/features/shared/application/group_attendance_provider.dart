import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'attendance_history_provider.dart';
import 'package:motify/core/constants/api_config.dart';

final groupAttendanceTodayProvider = FutureProvider<List<Attendance>>((
  ref,
) async {
  final token = ref.read(authNotifierProvider).token;
  if (token == null) throw Exception('No token found');
  final response = await http.get(
    Uri.parse('${ApiConfig.baseApiUrl}/attendance/by-group'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Attendance.fromJson(e)).toList();
  } else {
    throw Exception('Error loading group attendance');
  }
});
