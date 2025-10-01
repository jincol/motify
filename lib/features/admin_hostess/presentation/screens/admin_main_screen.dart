import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_dashboard_screen.dart';
import 'admin_team_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../../../core/widgets/main_drawer.dart';
import '../../../../../core/widgets/panel_app_bar.dart';

class AdminHostessMainScreen extends ConsumerStatefulWidget {
  const AdminHostessMainScreen({super.key});

  @override
  ConsumerState<AdminHostessMainScreen> createState() =>
      _AdminHostessMainScreenState();
}

class _AdminHostessMainScreenState
    extends ConsumerState<AdminHostessMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AdminAnfitrionaDashboardScreen(),
    AdminTeamScreen(),
    Center(child: Text('Geocercas')),
    Center(child: Text('Reportes')),
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
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
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFF9800),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                // Acción para agregar anfitriona
              },
            )
          : null,
      bottomNavigationBar: AdminHostessBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
