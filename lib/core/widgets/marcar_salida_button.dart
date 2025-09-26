import 'package:flutter/material.dart';

class MarcarSalidaButton extends StatelessWidget {
  final bool jornadaActiva;
  final Future<void> Function()? onMarcarSalida;

  const MarcarSalidaButton({
    Key? key,
    required this.jornadaActiva,
    required this.onMarcarSalida,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!jornadaActiva) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Marcar salida?'),
            content: const Text(
              '¿Estás seguro que deseas finalizar tu jornada?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                child: const Text('Confirmar'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        );
        if (confirm == true && onMarcarSalida != null) {
          await onMarcarSalida!();
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Marcar Salida'),
      backgroundColor: const Color(0xFFFB8C00),
    );
  }
}
