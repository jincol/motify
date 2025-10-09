import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:motify/core/widgets/team_list_view.dart';
import 'package:motify/core/models/user.dart';
import 'package:motify/core/widgets/confirmation_dialog.dart';
import '../widgets/rider_card.dart';

typedef OnUserDeleted = void Function();

class AdminTeamScreen extends ConsumerStatefulWidget {
  final OnUserDeleted? onUserDeleted;
  const AdminTeamScreen({super.key, this.onUserDeleted});

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
          itemBuilder: (context, user) => Slidable(
            key: ValueKey(user.id),
            child: SizedBox(
              height: 80,
              child: Slidable(
                key: ValueKey(user.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      flex: 2,
                      onPressed: (context) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => ConfirmationDialog(
                            title: 'Confirmar eliminación',
                            content:
                                '¿Estás seguro de que deseas eliminar este usuario?',
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref
                                .read(adminMotorizedUsersProvider.notifier)
                                .deleteUser(user.id);
                            if (widget.onUserDeleted != null) {
                              widget.onUserDeleted!();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al eliminar usuario: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Eliminar',
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ],
                ),
                child: RiderCard(
                  user: user,
                  onEdit: () {},
                  onDelete: () {},
                  onView: () {},
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
