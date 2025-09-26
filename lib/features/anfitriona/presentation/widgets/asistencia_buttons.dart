import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/features/anfitriona/application/asistencia_visual_notificador.dart';

class AsistenciaButtons extends ConsumerWidget {
  const AsistenciaButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciaState = ref.watch(asistenciaVisualProvider);
    final isLoading = asistenciaState.isLoading;
    final authState = ref.watch(authNotifierProvider);
    final workState = authState.workState;
    final puedeMarcarEntrada = workState == null || workState == 'INACTIVO';
    final puedeMarcarSalida = workState == 'JORNADA_ACTIVA';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: puedeMarcarEntrada && !isLoading
                ? () async {
                    await ref
                        .read(asistenciaVisualProvider.notifier)
                        .marcarEntrada(context);
                    await ref.read(authNotifierProvider.notifier).fetchMe();
                  }
                : null,
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            label: isLoading && asistenciaState.accion == 'entrada'
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'MARCAR ENTRADA',
                    style: TextStyle(color: Colors.white),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316), // Naranja corporativo
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              elevation: 4,
              shadowColor: const Color(0xFFF97316).withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: puedeMarcarSalida && !isLoading
                ? () async {
                    await ref
                        .read(asistenciaVisualProvider.notifier)
                        .marcarSalida(context);
                    await ref.read(authNotifierProvider.notifier).fetchMe();
                  }
                : null,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: isLoading && asistenciaState.accion == 'salida'
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'MARCAR SALIDA',
                    style: TextStyle(color: Colors.white),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: puedeMarcarSalida
                  ? const Color(
                      0xFF6366F1,
                    ) // Azul corporativo para salida activa
                  : Colors.grey[300], // Gris para deshabilitado
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              elevation: 4,
              shadowColor: const Color(0xFF6366F1).withOpacity(0.2),
            ),
          ),
        ),
      ],
    );
  }
}
