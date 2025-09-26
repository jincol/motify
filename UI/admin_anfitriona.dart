import 'package:flutter/material.dart';

class AdminAnfitrionaDashboard extends StatelessWidget {
  const AdminAnfitrionaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () {},
        ),
        title: const Text(
          'Dashboard Anfitrionas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs de Asistencia
            _buildAttendanceKpis(),
            const SizedBox(height: 24),

            // Lista de Asistencia del día
            _buildAttendanceList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.orange[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAttendanceKpis() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Presentes', '8', '/ 10')),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Ausentes', '2', '', Colors.red)),
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
              children: [
                const Text(
                  'Último Registro',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ana Gómez - 09:05 AM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String value, [
    String? subtitle,
    Color? valueColor,
  ]) {
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
                    color: valueColor ?? Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
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
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                Text(
                  '25/09',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEmployeeAttendanceCard(
          'Ana Gómez',
          'Presente - Sede Central',
          'AG',
          'Entrada: 09:05 AM',
        ),
        const SizedBox(height: 12),
        _buildEmployeeAttendanceCard(
          'Lucía Fernández',
          'Presente - Sucursal Norte',
          'LF',
          'Entrada: 09:02 AM',
        ),
      ],
    );
  }

  Widget _buildEmployeeAttendanceCard(
    String name,
    String status,
    String initials,
    String time,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
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
                      color: Colors.green,
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {},
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange[700],
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipo'),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined),
          label: 'Geocercas',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      ],
    );
  }
}
