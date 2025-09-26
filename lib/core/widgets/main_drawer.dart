import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 153, 0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color.fromARGB(221, 105, 70, 70),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Menú de Opciones',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Opciones del menú
          _buildDrawerItem(
            icon: Icons.person_outline,
            text: 'Ver/Editar Perfil',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            text: 'Historial de Asistencias',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            text: 'Ayuda y Configuración',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          Consumer(
            builder: (context, ref, _) => _buildDrawerItem(
              icon: Icons.logout,
              text: 'Cerrar sesión',
              onTap: () {
                ref.read(authNotifierProvider.notifier).logout();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para crear cada opción del menú
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryOrange),
      title: Text(
        text,
        style: const TextStyle(
          color: AppTheme.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
