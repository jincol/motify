import 'package:flutter/material.dart';
import '../../domain/models/rider.dart';

class RiderCard extends StatelessWidget {
  final Rider rider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const RiderCard({
    super.key,
    required this.rider,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(rider.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(rider.avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusInfo['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rider.status == RiderStatus.enRuta
                            ? '${statusInfo['text']} - Pedido #${rider.orderId}'
                            : statusInfo['text'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(137, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(RiderStatus status) {
    switch (status) {
      case RiderStatus.enRuta:
        return {'text': 'En Ruta', 'color': const Color(0xFF22C55E)};
      case RiderStatus.jornadaActiva:
        return {'text': 'Jornada Activa', 'color': const Color(0xFFFACC15)};
      case RiderStatus.inactivo:
        return {'text': 'Inactivo', 'color': const Color(0xFF9CA3AF)};
    }
  }
}
