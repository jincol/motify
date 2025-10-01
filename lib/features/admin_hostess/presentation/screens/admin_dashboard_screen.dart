import 'package:flutter/material.dart';
import '../widgets/kpi_card.dart';
import '../widgets/employee_attendance_card.dart';

class AdminAnfitrionaDashboardScreen extends StatelessWidget {
  const AdminAnfitrionaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos ficticios de asistencias
    final asistencias = [
      {
        'name': 'Ana Gómez',
        'status': 'Presente - Sede Central',
        'initials': 'AG',
        'time': 'Entrada: 09:05 AM',
      },
      {
        'name': 'Lucía Fernández',
        'status': 'Presente - Sucursal Norte',
        'initials': 'LF',
        'time': 'Entrada: 09:02 AM',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs Section
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'Presentes',
                  value: '8',
                  subtitle: '/ 10',
                  valueColor: const Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Ausentes',
                  value: '2',
                  valueColor: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Último registro (mejorado)
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
                    children: const [
                      Text(
                        'Último Registro',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ana Gómez - 09:05 AM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF222222),
                        ),
                        textAlign: TextAlign.center,
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
                    '25/09',
                    style: TextStyle(
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
          ...asistencias.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EmployeeAttendanceCard(
                name: a['name']!,
                status: a['status']!,
                initials: a['initials']!,
                time: a['time']!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
