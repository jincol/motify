import 'package:flutter/material.dart';

class JornadaControlWidget extends StatelessWidget {
  final VoidCallback onMarcarEntrada;
  final VoidCallback? onMarcarSalida;
  const JornadaControlWidget({
    Key? key,
    required this.onMarcarEntrada,
    this.onMarcarSalida,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white,
                semanticLabel: 'Cámara para marcar entrada',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Inicia tu Jornada',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Para ver tus pedidos, primero debes marcar tu entrada. Se requerirá una foto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMarcarEntrada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Marcar Entrada'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
