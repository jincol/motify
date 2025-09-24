import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/pedido.dart';
import 'status_badge.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;

  const PedidoCard({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    bool isFinalizado = pedido.status == PedidoStatus.finalizado;

    return Opacity(
      opacity: isFinalizado ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const FaIcon(FontAwesomeIcons.gripVertical, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pedido.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isFinalizado
                                ? Colors.grey[600]
                                : Colors.black87,
                            decoration: isFinalizado
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        StatusBadge(status: pedido.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recojo: ${pedido.recojo}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      'Entrega: ${pedido.entrega}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FaIcon(
                          pedido.iconoPaquete,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pedido.descripcionPaquete,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const FaIcon(FontAwesomeIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
