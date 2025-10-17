import 'package:flutter/material.dart';

class AdminHostessBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminHostessBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFF97316),
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipo'),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined),
          label: 'Geocercas',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      ],
    );
  }
}
