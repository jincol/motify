import 'package:flutter/material.dart';
import '../../models/pedido.dart';

class StatusBadge extends StatelessWidget {
  final PedidoStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PedidoStatus.pendiente:
        text = 'Pendiente';
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case PedidoStatus.enProceso:
        text = 'En Proceso';
        backgroundColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        break;
      case PedidoStatus.finalizado:
        text = 'Finalizado';
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
