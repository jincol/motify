/// Modelo para detalles de ubicación de usuario con información completa
class UserLocationDetail {
  final int userId;
  final String username;
  final String? name;
  final String? lastname;
  final String role;
  final String workState;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final double? speed;
  final double? heading;

  UserLocationDetail({
    required this.userId,
    required this.username,
    this.name,
    this.lastname,
    required this.role,
    required this.workState,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  String get displayName {
    if (name != null && lastname != null) {
      return '$name $lastname';
    }
    if (name != null) return name!;
    return username;
  }

  String get initials {
    if (name != null && lastname != null) {
      return '${name![0]}${lastname![0]}'.toUpperCase();
    }
    if (name != null && name!.length >= 2) {
      return name!.substring(0, 2).toUpperCase();
    }
    return username.substring(0, 2).toUpperCase();
  }

  factory UserLocationDetail.fromJson(Map<String, dynamic> json) {
    return UserLocationDetail(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      name: json['name'] as String?,
      lastname: json['lastname'] as String?,
      role: json['role'] as String,
      workState: json['work_state'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
    );
  }
}
