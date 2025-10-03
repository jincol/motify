import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/panel_app_bar.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:motify/core/widgets/attendance_history_list.dart';
import 'package:motify/features/shared/application/attendance_history_provider.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceHistoryProvider);
    return Scaffold(
      appBar: const PanelAppBar(
        title: 'Historial de Asistencia',
        showBackArrow: true,
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Esta Semana: 29 Sep - 03 Oct',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Aquí puedes abrir un selector de fechas o filtro
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF97316),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Filtrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de asistencias
          Expanded(
            child: attendanceAsync.when(
              data: (attendances) => AttendanceHistoryList(
                attendances: attendances,
                onDetail: (attendance) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(attendance.type),
                      content: Text(
                        'Hora: ${attendance.timestamp.hour.toString().padLeft(2, '0')}:${attendance.timestamp.minute.toString().padLeft(2, '0')}'
                        '\nFecha: ${attendance.timestamp.day.toString().padLeft(2, '0')}/${attendance.timestamp.month.toString().padLeft(2, '0')}/${attendance.timestamp.year}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
            ),
          ),
        ],
      ),
    );
  }
}
