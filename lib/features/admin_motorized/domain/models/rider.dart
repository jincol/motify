import 'package:flutter/material.dart';

enum RiderStatus { enRuta, jornadaActiva, inactivo }

class Rider {
  final String id;
  final String name;
  final RiderStatus status;
  final String? orderId;
  final String avatarUrl;

  Rider({
    required this.id,
    required this.name,
    required this.status,
    this.orderId,
    required this.avatarUrl,
  });
}
