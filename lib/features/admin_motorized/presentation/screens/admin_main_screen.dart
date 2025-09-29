import '../../../../core/widgets/rider_form.dart';
import '../../../../core/widgets/main_drawer.dart';
import '../../../../core/services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_team_screen.dart';

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

class AdminMotorizadoMainScreen extends StatefulWidget {
  const AdminMotorizadoMainScreen({super.key});

  @override
  State<AdminMotorizadoMainScreen> createState() =>
      _AdminMotorizadoMainScreenState();
}

class _AdminMotorizadoMainScreenState extends State<AdminMotorizadoMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AdminMotorizadoDashboardScreen(),
    AdminTeamScreen(),
    Center(child: Text('Chat')),
    Center(child: Text('Otro')),
  ];
  void _onAddMotorizado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) => RiderForm(
          title: 'Agregar Motorizado',
          onSubmit: (data) async {
            final authState = ref.watch(authNotifierProvider);
            if (authState.role == 'ADMIN_MOTORIZADO') {
              final userService = UserService();
              final response = await userService.createUser(
                nombre: data['nombre'],
                apellido: data['apellido'],
                usuario: data['usuario'],
                email: data['email'],
                contrasena: data['contrasena'],
                role: 'MOTORIZADO',
                telefono: data['telefono'],
                fotoUrl: null,
                token: authState.token!,
              );
              if (response.statusCode == 201) {
                // Usuario creado correctamente, actualiza la lista
                // setState o lógica para refrescar la pantalla
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al crear usuario')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No hay token. Inicia sesión nuevamente.'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _getTitleForIndex(_selectedIndex),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
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
      drawer: const MainDrawer(),
      body: _screens[_selectedIndex],
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
