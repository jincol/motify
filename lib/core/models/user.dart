import 'dart:convert';

class User {
  final int id;
  final String username;
  final String role;
  final String workState;
  final int? grupoId;
  final String? avatarUrl;
  final String? fullName; // <-- Nuevo campo
  final bool? isActive;
  final bool? isSuperuser;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.workState,
    this.grupoId,
    this.avatarUrl,
    this.fullName,
    this.isActive,
    this.isSuperuser,
  });

  String get name {
    // Si en el futuro tienes nombre/apellido separados, puedes adaptarlo aquí
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      workState: json['work_state'],
      grupoId: json['grupo_id'],
      avatarUrl: json['avatar_url'],
      fullName: json['full_name'],
      isActive: json['is_active'],
      isSuperuser: json['is_superuser'],
    );
  }
}

List<User> parseUsers(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => User.fromJson(json)).toList();
}
