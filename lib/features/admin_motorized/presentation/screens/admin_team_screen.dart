import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:motify/core/services/user_service.dart';
import 'package:motify/core/widgets/rider_form.dart';
import 'package:motify/core/widgets/team_list_view.dart';
import 'package:motify/core/models/user.dart';
import 'package:motify/core/widgets/confirmation_dialog.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
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
                  onEdit: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (modalContext) => Scaffold(
                        backgroundColor: Colors.transparent,
                        body: RiderForm(
                          title: 'Editar Motorizado',
                          initialNombre: user.name,
                          initialApellido: user.lastName,
                          initialEmail: user.email,
                          initialUsuario: user.username,
                          initialTelefono: user.phone,
                          initialPlaca: user.placaUnidad,
                          initialAvatarUrl: user.avatarUrl,
                          showPlaca: true,
                          isEditMode: true,
                          onSubmit: (data) async {
                            final token = ref.read(authNotifierProvider).token;
                            final userId = user.id.toString();

                            if (token == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se encontró el token de sesión',
                                  ),
                                ),
                              );
                              return;
                            }

                            final fieldsToUpdate = {
                              'name': data['nombre'],
                              'lastname': data['apellido'],
                              'email': data['email'],
                              'username': data['usuario'],

                              'phone': data['telefono'],
                              'placa_unidad': data['placa_unidad'],
                              'avatar_url': data['foto'],
                              // agrega otros campos si es necesario
                            };

                            fieldsToUpdate.removeWhere(
                              (key, value) => value == null || value == '',
                            );

                            if (data['contrasena'] != null &&
                                data['contrasena'].toString().isNotEmpty) {
                              fieldsToUpdate['password'] = data['contrasena'];
                            }

                            print('DEBUG fieldsToUpdate:');
                            fieldsToUpdate.forEach((k, v) => print('$k: $v'));
                            final response = await UserService().updateUser(
                              userId: userId,
                              fieldsToUpdate: fieldsToUpdate,
                              token: token,
                            );

                            if (response.statusCode == 200) {
                              if (context.mounted) {
                                Navigator.of(modalContext).pop();
                                ref.refresh(adminMotorizedUsersProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Usuario actualizado correctamente',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (modalContext.mounted) {
                                String errorMsg;
                                try {
                                  final decoded = jsonDecode(response.body);
                                  if (decoded is Map &&
                                      decoded.containsKey('detail')) {
                                    final detail = decoded['detail'];
                                    if (detail is List && detail.isNotEmpty) {
                                      errorMsg =
                                          detail[0]['msg'] ??
                                          'Error de validación';
                                    } else if (detail is String) {
                                      errorMsg = detail;
                                    } else {
                                      errorMsg = 'Ocurrió un error inesperado';
                                    }
                                  } else {
                                    errorMsg = 'Ocurrió un error inesperado';
                                  }
                                } catch (_) {
                                  errorMsg = 'Ocurrió un error inesperado';
                                }
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            errorMsg,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[700],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    duration: Duration(seconds: 2),
                                    elevation: 10,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
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
