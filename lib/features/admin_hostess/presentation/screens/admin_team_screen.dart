import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/services/user_service.dart';
import 'package:motify/core/widgets/rider_form.dart';
import 'package:motify/core/widgets/team_list_view.dart';
// import 'package:motify/features/admin_hostess/application/users_providers.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/features/shared/application/attendance_history_provider.dart';
import 'package:motify/features/shared/application/group_attendance_provider.dart';
import '../widgets/hostess_card.dart';
import 'anfitriona_detail_page.dart';

typedef OnUserDeleted = void Function();

class AdminTeamScreen extends ConsumerStatefulWidget {
  final OnUserDeleted? onUserDeleted;
  const AdminTeamScreen({super.key, this.onUserDeleted});

  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminHostessUsersProvider);

    return usersAsync.when(
      data: (users) => TeamListView(
        users: users,
        filters: const [],
        itemBuilder: (context, user) => Slidable(
          key: ValueKey(user.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                flex: 2,
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar eliminación'),
                      content: const Text(
                        '¿Estás seguro de que deseas eliminar esta anfitriona?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref
                          .read(adminHostessUsersProvider.notifier)
                          .deleteUser(user.id);
                      ref.refresh(groupAttendanceTodayProvider);
                      if (widget.onUserDeleted != null) {
                        widget.onUserDeleted!();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al eliminar anfitriona: $e'),
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
          child: GestureDetector(
            onTap: () {
              final userId = ref.read(authNotifierProvider).userId;
              if (userId != null) {
                ref.invalidate(attendanceHistoryProvider(userId));
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnfitrionaDetailPage(user: user),
                ),
              );
            },
            child: HostessCard(
              user: user,
              onEdit: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (modalContext) => Scaffold(
                    backgroundColor: Colors.transparent,
                    body: RiderForm(
                      title: 'Editar Anfitriona',
                      initialNombre: user.name,
                      initialApellido: user.lastName,
                      initialEmail: user.email,
                      initialUsuario: user.username,
                      initialTelefono: user.phone,
                      initialAvatarUrl: user.avatarUrl,
                      showPlaca: false,
                      isEditMode: true,
                      onSubmit: (data) async {
                        final token = ref
                            .read(adminHostessUsersProvider.notifier)
                            .ref
                            .read(authNotifierProvider)
                            .token;
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
                          'avatar_url': data['foto'],
                        };

                        fieldsToUpdate['full_name'] =
                            '${data['nombre']} ${data['apellido']}';
                        fieldsToUpdate.removeWhere(
                          (key, value) => value == null || value == '',
                        );

                        if (data['contrasena'] != null &&
                            data['contrasena'].toString().isNotEmpty) {
                          fieldsToUpdate['password'] = data['contrasena'];
                        }

                        final response = await UserService().updateUser(
                          userId: userId,
                          fieldsToUpdate: fieldsToUpdate,
                          token: token,
                        );

                        if (response.statusCode == 200) {
                          if (context.mounted) {
                            Navigator.of(modalContext).pop();
                            ref.refresh(adminHostessUsersProvider);
                            ScaffoldMessenger.of(modalContext).showSnackBar(
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
                                      detail[0]['msg'] ?? 'Error de validación';
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
