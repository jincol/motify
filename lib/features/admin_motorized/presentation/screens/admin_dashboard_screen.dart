import 'package:motify/features/admin_motorized/application/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/models/user.dart';
import '../widgets/team_member_card.dart';
import '../widgets/map_placeholder.dart';
import 'package:flutter/material.dart';
import '../widgets/kpi_card.dart';

String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

class AdminMotorizadoDashboardScreen extends ConsumerWidget {
  const AdminMotorizadoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(motorizadoUsersProvider);
    return usersAsync.when(
      data: (users) {
        final activos = users
            .where(
              (u) =>
                  u.workState == 'EN_RUTA' || u.workState == 'JORNADA_ACTIVA',
            )
            .toList();
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
                      value: activos.length.toString(),
                      subtitle: '/ ${users.length}',
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Pedidos Completados',
                      value: '84', // Placeholder
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
              ...activos.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamMemberCard(
                    name: capitalize(user.username),
                    status: user.workState == 'EN_RUTA'
                        ? 'En ruta'
                        : 'Jornada activa',
                    initials: user.username.isNotEmpty
                        ? user.username.substring(0, 2).toUpperCase()
                        : '?',
                    statusColor: user.workState == 'EN_RUTA'
                        ? Colors.green
                        : Colors.orange,
                    avatarUrl: user.avatarUrl,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
