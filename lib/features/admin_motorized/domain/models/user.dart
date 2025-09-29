import 'dart:convert';

class User {
  final int id;
  final String username;
  final String role;
  final String workState;
  final int? grupoId;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.workState,
    this.grupoId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      workState: json['work_state'],
      grupoId: json['grupo_id'],
    );
  }
}

List<User> parseUsers(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => User.fromJson(json)).toList();
}
