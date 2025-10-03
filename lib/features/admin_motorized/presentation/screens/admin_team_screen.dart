import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:motify/core/widgets/team_list_view.dart';
import 'package:motify/core/models/user.dart';
import '../../application/users_provider.dart';
import '../widgets/rider_card.dart';

class AdminTeamScreen extends ConsumerStatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  String? _activeFilter;

  List<User> _filterUsers(List<User> users, String? status) {
    if (status == null) return users;
    return users.where((u) => u.workState == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminMotorizedUsersProvider);

    return usersAsync.when(
      data: (users) {
        final filteredUsers = _filterUsers(users, _activeFilter);
        return TeamListView<User>(
          users: filteredUsers,
          filters: [
            FilterChip(
              label: const Text('Todos'),
              selected: _activeFilter == null,
              onSelected: (selected) => setState(() => _activeFilter = null),
              selectedColor: const Color(0xFFF97316).withOpacity(0.15),
              labelStyle: TextStyle(
                color: _activeFilter == null
                    ? const Color(0xFFF97316)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilterChip(
              label: const Text('En Ruta'),
              selected: _activeFilter == 'en_ruta',
              onSelected: (selected) =>
                  setState(() => _activeFilter = 'en_ruta'),
              selectedColor: const Color(0xFFF97316).withOpacity(0.15),
              labelStyle: TextStyle(
                color: _activeFilter == 'en_ruta'
                    ? const Color(0xFFF97316)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilterChip(
              label: const Text('Jornada Activa'),
              selected: _activeFilter == 'jornada_activa',
              onSelected: (selected) =>
                  setState(() => _activeFilter = 'jornada_activa'),
              selectedColor: const Color(0xFFF97316).withOpacity(0.15),
              labelStyle: TextStyle(
                color: _activeFilter == 'jornada_activa'
                    ? const Color(0xFFF97316)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilterChip(
              label: const Text('Inactivos'),
              selected: _activeFilter == 'inactivo',
              onSelected: (selected) =>
                  setState(() => _activeFilter = 'inactivo'),
              selectedColor: const Color(0xFFF97316).withOpacity(0.15),
              labelStyle: TextStyle(
                color: _activeFilter == 'inactivo'
                    ? const Color(0xFFF97316)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          itemBuilder: (context, user) => RiderCard(
            user: user,
            onEdit: () {},
            onDelete: () {},
            onView: () {},
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
