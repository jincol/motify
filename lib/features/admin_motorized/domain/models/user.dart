import 'dart:convert';

class User {
  final int id;
  final String username;
  final String role;
  final String workState;
  final int? grupoId;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.workState,
    this.grupoId,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      workState: json['work_state'],
      grupoId: json['grupo_id'],
      avatarUrl: json['avatar_url'],
    );
  }
}

List<User> parseUsers(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => User.fromJson(json)).toList();
}
