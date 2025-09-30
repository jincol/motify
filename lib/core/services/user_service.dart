import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/admin_motorized/domain/models/user.dart';

class UserService {
  static const String _baseUrl = 'http://192.168.31.166:8000/api/v1/users/';

  Future<http.Response> createUser({
    required String nombre,
    required String apellido,
    required String usuario,
    required String email,
    required String contrasena,
    required String role,
    String? telefono,
    String? placaUnidad,
    String? fotoUrl,
    required String token,
  }) async {
    final Map<String, dynamic> body = {
      'username': usuario,
      'email': email,
      'full_name': '$nombre $apellido',
      'password': contrasena,
      'role': role,
      'phone': telefono,
      'placa_unidad': placaUnidad,
      'avatar_url': fotoUrl,
    };

    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> getUsers({required String token, String? role}) async {
    final uri = Uri.parse('$_baseUrl?role=${role ?? ""}');
    return await http.get(uri, headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<User>> fetchUsers({required String token, String? role}) async {
    final response = await getUsers(token: token, role: role);
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception(
        'Falla en la carga de usuarios: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<http.Response> updateAvatarUrl({
    required String userId,
    required String avatarUrl,
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'avatar_url': avatarUrl}),
    );
    return response;
  }
}
