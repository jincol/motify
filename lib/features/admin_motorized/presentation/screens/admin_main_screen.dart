import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_team_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: _screens[_selectedIndex],
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
