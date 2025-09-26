import 'package:motify/core/widgets/jornada_control_widget.dart';
import 'package:motify/core/services/attendance_service.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

class JornadaControlScreen extends StatelessWidget {
  const JornadaControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Jornada')),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: JornadaControlWidget(
            onMarcarEntrada: () {
              AttendanceService.marcarAsistencia(
                context: context,
                tipo: 'check-in',
                onSuccess: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/dashboard_anfitriona',
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
