import 'package:flutter/material.dart';
import '../../../../core/widgets/main_drawer.dart';
import '../widgets/asistencia_card.dart';
import '../widgets/asistencia_buttons.dart';
import '../widgets/anfitriona_bottom_nav.dart';

class AsistenciaAnfitrionaScreen extends StatelessWidget {
  const AsistenciaAnfitrionaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Control de Asistencia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.watch_later_outlined,
              size: 90,
              color: const Color(0xFFF97316),
            ),
            const SizedBox(height: 32),
            const AsistenciaCard(),
            const SizedBox(height: 32),
            const AsistenciaButtons(),
            const Spacer(flex: 2),
          ],
        ),
      ),
      bottomNavigationBar: const AnfitrionaBottomNav(),
    );
  }
}
