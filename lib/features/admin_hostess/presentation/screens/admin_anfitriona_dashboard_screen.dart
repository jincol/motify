import 'package:flutter/material.dart';
import '../../../../core/widgets/panel_app_bar.dart';
import '../../../../core/widgets/main_drawer.dart';
import 'package:motify/features/admin_hostess/presentation/widgets/bottom_nav_bar.dart';

/// Colores corporativos (ajusta si tienes un archivo de tema global)
const Color kPrimaryColor = Color(0xFFFF9800); // Naranja Motify
const Color kBackgroundColor = Color(0xFFFFF8F0);
const Color kCardColor = Colors.white;
const Color kAccentColor = Color(0xFF222222);
const Color kKpiPresentColor = Color(0xFF43A047); // Verde
const Color kKpiAbsentColor = Color(0xFFE53935); // Rojo

class AdminAnfitrionaDashboardScreen extends StatelessWidget {
  const AdminAnfitrionaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: const PanelAppBar(
        title: 'Dashboard Anfitrionas',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AttendanceKpis(),
            const SizedBox(height: 24),
            _AttendanceList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AdminHostessBottomNavBar(
        currentIndex: 0, // o el índice actual de la pestaña
        onTap: (index) {
          // tu lógica de navegación aquí
        },
      ),
    );
  }
}

/// KPIs de asistencia
class _AttendanceKpis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Presentes',
                value: '8',
                subtitle: '/ 10',
                valueColor: kKpiPresentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KpiCard(
                title: 'Ausentes',
                value: '2',
                valueColor: kKpiAbsentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: const [
                Text(
                  'Último Registro',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Ana Gómez - 09:05 AM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kAccentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color valueColor;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor = kAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: valueColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de asistencias del día
class _AttendanceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Asistencia del Día',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kAccentColor,
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EmployeeAttendanceCard(
          name: 'Ana Gómez',
          status: 'Presente - Sede Central',
          initials: 'AG',
          time: 'Entrada: 09:05 AM',
        ),
        const SizedBox(height: 12),
        _EmployeeAttendanceCard(
          name: 'Lucía Fernández',
          status: 'Presente - Sucursal Norte',
          initials: 'LF',
          time: 'Entrada: 09:02 AM',
        ),
      ],
    );
  }
}

class _EmployeeAttendanceCard extends StatelessWidget {
  final String name;
  final String status;
  final String initials;
  final String time;

  const _EmployeeAttendanceCard({
    required this.name,
    required this.status,
    required this.initials,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kPrimaryColor,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      color: kKpiPresentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
