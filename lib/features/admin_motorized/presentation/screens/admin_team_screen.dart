import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
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
    // Usamos el nuevo provider específico para motorizados.
    final usersAsync = ref.watch(motorizadoUsersProvider);

    return usersAsync.when(
      data: (users) {
        final filteredUsers = _filterUsers(users, _activeFilter);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8.0,
                  children: <Widget>[
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _activeFilter == null,
                      onSelected: (selected) =>
                          setState(() => _activeFilter = null),
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
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return RiderCard(
                    user: user,
                    onEdit: () {}, // Implementa edición real
                    onDelete: () {}, // Implementa borrado real
                    onView: () {},
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
