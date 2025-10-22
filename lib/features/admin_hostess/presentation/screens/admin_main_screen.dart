import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/services/photo_service.dart';
import 'package:motify/core/services/user_service.dart';
import 'package:motify/features/admin_hostess/application/users_providers.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/features/admin_hostess/presentation/screens/admin_dashboard_screen.dart';
import 'package:motify/features/admin_hostess/presentation/screens/admin_team_screen.dart';
import 'package:motify/features/admin_hostess/presentation/widgets/bottom_nav_bar.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:motify/core/widgets/panel_app_bar.dart';
import 'package:motify/core/widgets/rider_form.dart';
import 'package:motify/features/shared/application/group_attendance_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'dart:convert';
import 'package:motify/core/constants/api_config.dart';

class AdminHostessMainScreen extends ConsumerStatefulWidget {
  const AdminHostessMainScreen({super.key});

  @override
  ConsumerState<AdminHostessMainScreen> createState() =>
      _AdminHostessMainScreenState();
}

class _AdminHostessMainScreenState
    extends ConsumerState<AdminHostessMainScreen> {
  int _selectedIndex = 0;
  late WebSocketChannel channel;

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Anfitrionas';
      case 1:
        return 'Gestión de Equipo';
      case 2:
        return 'Geocercas';
      case 3:
        return 'Reportes';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      final authState = ref.read(authNotifierProvider);
      final token = authState.token;
      final host = ApiConfig.baseUrl.replaceAll(RegExp(r"/api/v1$"), "");
      final hostNoScheme = host.replaceAll(RegExp(r"^https?://"), "");
      channel = WebSocketChannel.connect(
        Uri.parse('ws://$hostNoScheme/ws/events?token=$token'),
      );
      channel.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'estado_actualizado') {
            final usuarioId = data['usuario_id'];
            final nuevoEstado = data['nuevo_estado'];
            ref
                .read(adminHostessUsersProvider.notifier)
                .updateUserState(usuarioId, nuevoEstado);
            ref.refresh(groupAttendanceTodayProvider);
          }
        },
        onError: (error) {},
        onDone: () {
          print('WebSocket cerrado');
        },
      );
    } catch (e, st) {
      print('Error al conectar WebSocket: $e\n$st');
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminAnfitrionaDashboardScreen(),
      AdminTeamScreen(
        onUserDeleted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anfitriona eliminada correctamente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              duration: Duration(seconds: 2),
              elevation: 8,
            ),
          );
        },
      ),
      Center(child: Text('Geocercas')),
      Center(child: Text('Reportes')),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 245, 244),
      appBar: PanelAppBar(
        title: _getTitleForIndex(_selectedIndex),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFF9800),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (modalContext) => Scaffold(
                    backgroundColor: Colors.transparent,
                    body: RiderForm(
                      title: 'Agregar Anfitriona',
                      onSubmit: (data) async {
                        final authState = ref.read(authNotifierProvider);
                        if (authState.token != null &&
                            authState.role == 'ADMIN_ANFITRIONA') {
                          String? fotoUrl = data['foto'];
                          final userService = UserService();
                          final response = await userService.createUser(
                            nombre: data['nombre'],
                            apellido: data['apellido'],
                            usuario: data['usuario'],
                            email: data['email'],
                            contrasena: data['contrasena'],
                            role: 'ANFITRIONA',
                            telefono: data['telefono'],
                            fotoUrl: fotoUrl,
                            token: authState.token!,
                          );
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
                          if (response.statusCode == 201) {
                            await ref
                                .read(adminHostessUsersProvider.notifier)
                                .refresh();
                            ref.refresh(groupAttendanceTodayProvider);
                            Navigator.of(modalContext).pop(true);
                          } else {
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
                        } else {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No hay token. Inicia sesión nuevamente.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Usuario creado correctamente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange[500],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      duration: Duration(seconds: 2),
                      elevation: 8,
                    ),
                  );
                }
              },
            )
          : null,
      bottomNavigationBar: AdminHostessBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            ref.read(adminHostessUsersProvider.notifier).refresh();
            ref.refresh(groupAttendanceTodayProvider);
          }
        },
      ),
    );
  }
}
