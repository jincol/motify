import 'package:flutter/material.dart';

class AsistenciaCard extends StatelessWidget {
  const AsistenciaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Fuera de Jornada',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Último registro: Ayer - 06:00 PM',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
