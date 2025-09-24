import 'package:flutter/material.dart';

enum PedidoStatus { pendiente, enProceso, finalizado }

class Pedido {
  final String titulo;
  final String recojo;
  final String entrega;
  final String descripcionPaquete;
  final IconData iconoPaquete;
  final PedidoStatus status;

  Pedido({
    required this.titulo,
    required this.recojo,
    required this.entrega,
    required this.descripcionPaquete,
    required this.iconoPaquete,
    required this.status,
  });
}
