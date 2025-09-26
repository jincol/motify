import 'package:flutter/material.dart';

// Nota: Para usar los íconos como en el mockup, podrías necesitar
// un paquete como `iconsax` o `eva_icons`. Aquí usamos los de Material Design.
// Para usar la fuente 'Inter', agrégala a tu pubspec.yaml y a la carpeta de assets.

class AdminMotorizadoDashboard extends StatelessWidget {
  const AdminMotorizadoDashboard({super.key});

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
          'Dashboard',
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
            // KPIs Section
            _buildKpiGrid(),
            const SizedBox(height: 24),

            // Mapa Section
            _buildMapPlaceholder(),
            const SizedBox(height: 24),

            // Equipo en Actividad Section
            _buildTeamActivityList(),
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

  Widget _buildKpiGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Motorizados Activos', '12', '/ 15')),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Pedidos Completados', '84')),
          ],
        ),
        const SizedBox(height: 16),
        _buildKpiCard('Tiempo Promedio', '25 min', '', isFullWidth: true),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String value, [
    String? subtitle,
    bool isFullWidth = false,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.black87,
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

  Widget _buildMapPlaceholder() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://placehold.co/600x300/E2E8F0/4A5568?text=Mapa+en+Vivo',
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamActivityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Equipo en Actividad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            Text(
              'Ver Todo >',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTeamMemberCard(
          'Carlos Vega',
          'En Ruta - Pedido #5421',
          'CV',
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildTeamMemberCard(
          'Juan Pérez',
          'Jornada Activa',
          'JP',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTeamMemberCard(
    String name,
    String status,
    String initials,
    Color statusColor,
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
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
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
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
      ],
    );
  }
}
