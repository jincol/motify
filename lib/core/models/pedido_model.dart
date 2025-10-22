class PedidoModel {
  final int id;
  final String codigoPedido;
  final int motorizadoId;
  final String titulo;
  final String nombreRemitente;
  final String? telefono;
  final String? descripcion;
  final String? instrucciones;
  final String estado; // 'pendiente', 'en_proceso', 'finalizado'
  final List<ParadaModel> paradas;
  final DateTime? fechaCreacion;
  final DateTime? fechaAsignacion;

  PedidoModel({
    required this.id,
    required this.codigoPedido,
    required this.motorizadoId,
    required this.titulo,
    required this.nombreRemitente,
    this.telefono,
    this.descripcion,
    this.instrucciones,
    required this.estado,
    required this.paradas,
    this.fechaCreacion,
    this.fechaAsignacion,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id_pedido'],
      codigoPedido: json['codigo_pedido'],
      motorizadoId: json['motorizado_id'],
      titulo: json['titulo'],
      nombreRemitente: json['nombre_remitente'],
      telefono: json['telefono_remitente'],
      descripcion: json['descripcion'],
      instrucciones: json['instrucciones'],
      estado: json['estado'],
      paradas:
          (json['paradas'] as List?)
              ?.map((p) => ParadaModel.fromJson(p))
              .toList() ??
          [],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.parse(json['fecha_asignacion'])
          : null,
    );
  }
}

class ParadaModel {
  final int id;
  final int pedidoId;
  final String tipo;
  final String? direccion;
  final int orden;
  final String? fotoUrl;
  final double? gpsLat;
  final double? gpsLng;
  final DateTime? fechaHora;
  final bool confirmado;
  final String? notas;

  ParadaModel({
    required this.id,
    required this.pedidoId,
    required this.tipo,
    this.direccion,
    required this.orden,
    this.fotoUrl,
    this.gpsLat,
    this.gpsLng,
    this.fechaHora,
    required this.confirmado,
    this.notas,
  });

  factory ParadaModel.fromJson(Map<String, dynamic> json) {
    return ParadaModel(
      id: json['id_parada'],
      pedidoId: json['pedido_id'],
      tipo: json['tipo'],
      direccion: json['direccion'], // Puede ser null
      orden: json['orden'],
      fotoUrl: json['foto_url'],
      gpsLat: json['gps_lat'],
      gpsLng: json['gps_lng'],
      fechaHora: json['fecha_hora'] != null
          ? DateTime.parse(json['fecha_hora'])
          : null,
      confirmado: json['confirmado'] ?? false,
      notas: json['notas'],
    );
  }

  // Método para convertir a JSON (útil para enviar al backend)
  Map<String, dynamic> toJson() {
    return {
      'id_parada': id,
      'pedido_id': pedidoId,
      'tipo': tipo,
      'direccion': direccion,
      'orden': orden,
      'foto_url': fotoUrl,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'fecha_hora': fechaHora?.toIso8601String(),
      'confirmado': confirmado,
      'notas': notas,
    };
  }

  // Método copyWith para actualizar campos específicos
  ParadaModel copyWith({
    int? id,
    int? pedidoId,
    String? tipo,
    String? direccion,
    int? orden,
    String? fotoUrl,
    double? gpsLat,
    double? gpsLng,
    DateTime? fechaHora,
    bool? confirmado,
    String? notas,
  }) {
    return ParadaModel(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      tipo: tipo ?? this.tipo,
      direccion: direccion ?? this.direccion,
      orden: orden ?? this.orden,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      fechaHora: fechaHora ?? this.fechaHora,
      confirmado: confirmado ?? this.confirmado,
      notas: notas ?? this.notas,
    );
  }
}
