import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/main_drawer.dart';
import '../../../../core/widgets/panel_app_bar.dart';
import '../../../../core/widgets/rider_form.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_team_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

String _getTitleForIndex(int index) {
  switch (index) {
    case 0:
      return 'Panel Motorizados';
    case 1:
      return 'Gestión de Equipo';
    case 2:
      return 'Reportes';
    case 3:
      return 'Chat';
    default:
      return '';
  }
}

class AdminMotorizadoMainScreen extends ConsumerStatefulWidget {
  const AdminMotorizadoMainScreen({super.key});

  @override
  ConsumerState<AdminMotorizadoMainScreen> createState() =>
      _AdminMotorizadoMainScreenState();
}

class _AdminMotorizadoMainScreenState
    extends ConsumerState<AdminMotorizadoMainScreen> {
  int _selectedIndex = 0;

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      try {
        final authState = ref.read(authNotifierProvider);
        final token = authState.token;
        if (token == null) return;
        final wsUrl = 'ws://192.168.31.166:8000/ws/events?token=$token';
        final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        channel.stream.listen(
          (message) {
            try {
              final data = jsonDecode(message);
              if (data['type'] == 'estado_actualizado') {
                final usuarioId = data['usuario_id'];
                final nuevoEstado = data['nuevo_estado'];
                ref
                    .read(adminMotorizedUsersProvider.notifier)
                    .updateUserState(usuarioId, nuevoEstado);
              }
            } catch (e) {
              print('Error procesando mensaje WebSocket: $e');
            }
          },
          onError: (error) {
            print('Error en WebSocket: $error');
          },
          onDone: () {
            print('WebSocket cerrado');
          },
        );
      } catch (e, st) {
        print('Error al conectar WebSocket: $e\n$st');
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _onAddMotorizado() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => RiderForm(
        title: 'Agregar Motorizado',
        onSubmit: (data) async {
          final authState = ref.read(authNotifierProvider);
          if (authState.role == 'ADMIN_MOTORIZADO') {
            String? fotoUrl;
            if (data['foto'] != null) {
              fotoUrl = await PhotoService.uploadPhoto(
                data['foto'],
                tipo: 'profile',
              );
            }
            final userService = UserService();
            final response = await userService.createUser(
              nombre: data['nombre'],
              apellido: data['apellido'],
              usuario: data['usuario'],
              email: data['email'],
              contrasena: data['contrasena'],
              role: 'MOTORIZADO',
              telefono: data['telefono'],
              placaUnidad: data['placa_unidad'],
              fotoUrl: fotoUrl,
              token: authState.token!,
            );
            if (response.statusCode == 201) {
              ref.read(adminMotorizedUsersProvider.notifier).refresh();
              Navigator.of(modalContext).pop(true);
            } else {
              ScaffoldMessenger.of(
                modalContext,
              ).showSnackBar(SnackBar(content: Text('Error al crear usuario')));
            }
          } else {
            ScaffoldMessenger.of(modalContext).showSnackBar(
              SnackBar(
                content: Text('No hay token. Inicia sesión nuevamente.'),
              ),
            );
          }
        },
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Usuario creado correctamente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[500],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          duration: Duration(seconds: 2),
          elevation: 8,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminMotorizadoDashboardScreen(),
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
                      'Usuario eliminado correctamente',
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
      Center(child: Text('Chat')),
      Center(child: Text('Otro')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
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
              backgroundColor: const Color(0xFFF97316),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: _onAddMotorizado,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
