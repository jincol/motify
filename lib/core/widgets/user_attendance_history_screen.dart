import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/panel_app_bar.dart';
import 'package:motify/core/widgets/attendance_history_list.dart';
import 'package:motify/features/shared/application/attendance_history_provider.dart';

class UserAttendanceHistoryScreen extends ConsumerWidget {
  final int userId;
  final String userName;

  const UserAttendanceHistoryScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceHistoryProvider(userId));

    return Scaffold(
      appBar: PanelAppBar(title: 'Historial de $userName', showBackArrow: true),
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
                      'Historial de Asistencias',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
