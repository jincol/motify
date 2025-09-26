import 'package:motify/core/widgets/jornada_control_widget.dart';
import 'package:motify/core/services/attendance_service.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

class JornadaControlScreen extends ConsumerWidget {
  const JornadaControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Jornada')),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: JornadaControlWidget(
            onMarcarEntrada: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await AttendanceService.marcarAsistencia(
                context: context,
                tipo: 'check-in',
                onSuccess: () {
                  Navigator.of(context).pop(); // Cierra el loader
                  Navigator.pushReplacementNamed(context, '/motorizadoPage');
                },
              );
            },
            onMarcarSalida: () async {
              await AttendanceService.marcarAsistencia(
                context: context,
                tipo: 'check-out',
                onSuccess: () async {
                  await ref.read(authNotifierProvider.notifier).fetchMe();
                  Navigator.pushReplacementNamed(context, '/motorizadoJornada');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
