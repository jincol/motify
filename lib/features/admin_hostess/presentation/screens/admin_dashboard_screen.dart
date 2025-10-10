import 'package:flutter/material.dart';
import 'package:motify/core/models/user.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:motify/features/admin_hostess/application/users_providers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/employee_attendance_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/shared/application/group_attendance_provider.dart';
import 'package:intl/intl.dart';

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

class AdminAnfitrionaDashboardScreen extends ConsumerWidget {
  const AdminAnfitrionaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(groupAttendanceTodayProvider);
    final usersAsync = ref.watch(adminHostessUsersProvider);

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (asistencias) {
        return usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (users) {
            final presentes = asistencias.map((a) => a.userId).toSet().length;
            final total = users.length;
            final ausentes = (total - presentes).clamp(0, total);

            final asistenciasOrdenadas = [...asistencias]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            final asistenciasPorUsuario = <int, List<dynamic>>{};
            for (var a in asistenciasOrdenadas) {
              asistenciasPorUsuario.putIfAbsent(a.userId, () => []).add(a);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: KpiCard(
                          title: 'Presentes',
                          value: presentes.toString(),
                          subtitle: '/ $total',
                          valueColor: const Color(0xFF43A047),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KpiCard(
                          title: 'Ausentes',
                          value: ausentes.toString(),
                          valueColor: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Último registro
                  if (asistenciasOrdenadas.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 32,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Último Registro',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Builder(
                                  builder: (context) {
                                    final last = asistenciasOrdenadas.first;
                                    User? user;
                                    try {
                                      user = users.firstWhere(
                                        (u) => u.id == last.userId,
                                      );
                                    } catch (_) {
                                      user = null;
                                    }
                                    final nombre =
                                        (user?.name ?? '').trim().isNotEmpty
                                        ? (user!.name ?? '')
                                              .split(' ')
                                              .map(capitalize)
                                              .join(' ')
                                        : 'Desconocido';
                                    final hora = DateFormat(
                                      'HH:mm',
                                    ).format(last.timestamp.toLocal());
                                    return Text(
                                      '$nombre - $hora',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF222222),
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Asistencia del Día
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Asistencia del Día',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF222222),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Hoy',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...asistenciasPorUsuario.entries.map((entry) {
                    final userId = entry.key;
                    final asistenciasUsuario = entry.value;

                    // Busca la primera entrada y la última salida
                    final entrada = asistenciasUsuario.firstWhere(
                      (a) => a.type == 'check-in',
                      orElse: () => null,
                    );
                    final salida = asistenciasUsuario.lastWhere(
                      (a) => a.type == 'check-out',
                      orElse: () => null,
                    );

                    User? user;
                    try {
                      user = users.firstWhere((u) => u.id == userId);
                    } catch (_) {
                      user = null;
                    }
                    final nombre = (user?.name ?? '').trim().isNotEmpty
                        ? (user!.name ?? '')
                              .split(' ')
                              .map(capitalize)
                              .join(' ')
                        : 'Desconocido';
                    final initials = nombre.isNotEmpty
                        ? nombre.substring(0, 2).toUpperCase()
                        : '?';

                    String horario = '';
                    if (entrada != null) {
                      horario =
                          'Entrada: ${DateFormat('HH:mm').format(entrada.timestamp.toLocal())}';
                    }
                    if (salida != null) {
                      horario +=
                          ' - Salida: ${DateFormat('HH:mm').format(salida.timestamp.toLocal())}';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EmployeeAttendanceCard(
                        name: nombre,
                        status:
                            'Presente - Sede Central', // Puedes ajustar según tu lógica
                        initials: initials,
                        time: horario,
                        avatarUrl: user?.avatarUrl,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
