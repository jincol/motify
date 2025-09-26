import 'package:flutter/material.dart';
import '../widgets/kpi_card.dart';
import '../widgets/team_member_card.dart';
import '../widgets/map_placeholder.dart';

class AdminMotorizadoDashboardScreen extends StatelessWidget {
  const AdminMotorizadoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
