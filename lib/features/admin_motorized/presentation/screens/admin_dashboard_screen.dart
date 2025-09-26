import 'package:flutter/material.dart';
import '../widgets/kpi_card.dart';
import '../widgets/team_member_card.dart';
import '../widgets/map_placeholder.dart';

class AdminMotorizadoDashboardScreen extends StatelessWidget {
  const AdminMotorizadoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Panel Motorizados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
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
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Motorizados Activos',
                    value: '12',
                    subtitle: '/ 15',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: 'Pedidos Completados',
                    value: '84',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Mapa Section
            const MapPlaceholder(),
            const SizedBox(height: 24),
            // Equipo en Actividad Section
            const Text(
              'Equipo en Actividad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TeamMemberCard(
              name: 'Carlos Vega',
              status: 'En Ruta - Pedido #5421',
              initials: 'CV',
              statusColor: Colors.green,
            ),
            const SizedBox(height: 12),
            TeamMemberCard(
              name: 'Juan Pérez',
              status: 'Jornada Activa',
              initials: 'JP',
              statusColor: Colors.orange,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF97316),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Si usas navegación clásica, aquí puedes dejar el BottomNavigationBar
    );
  }
}
