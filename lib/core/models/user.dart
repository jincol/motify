import 'dart:convert';

class User {
  final int id;
  final String username;
  final String role;
  final String workState;
  final int? grupoId;
  final String? avatarUrl;
  final String? fullName;
  final String? name;
  final String? lastName;
  final bool? isActive;
  final bool? isSuperuser;
  final String? email;
  final String? phone;
  final String? placaUnidad;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.workState,
    this.grupoId,
    this.avatarUrl,
    this.fullName,
    this.name,
    this.lastName,
    this.isActive,
    this.isSuperuser,
    this.email,
    this.phone,
    this.placaUnidad,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return username;
  }

  User copyWith({
    int? id,
    String? username,
    String? role,
    String? workState,
    int? grupoId,
    String? avatarUrl,
    String? fullName,
    String? name,
    String? lastName,
    bool? isActive,
    bool? isSuperuser,
    String? email,
    String? phone,
    String? placaUnidad,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      workState: workState ?? this.workState,
      grupoId: grupoId ?? this.grupoId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      placaUnidad: placaUnidad ?? this.placaUnidad,
    );
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
      name: json['name'],
      lastName: json['lastname'],
      isActive: json['is_active'],
      isSuperuser: json['is_superuser'],
      email: json['email'],
      phone: json['phone'],
      placaUnidad: json['placa_unidad'],
    );
  }
}

List<User> parseUsers(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => User.fromJson(json)).toList();
}
