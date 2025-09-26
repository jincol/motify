import 'package:flutter/material.dart';

class AnfitrionaBottomNav extends StatelessWidget {
  const AnfitrionaBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {},
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFF97316),
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Asistencia',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
      ],
    );
  }
}
