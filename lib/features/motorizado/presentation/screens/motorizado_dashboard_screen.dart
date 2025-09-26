import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:motify/core/widgets/marcar_salida_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/core/services/attendance_service.dart';
import '../../models/pedido.dart';
import '../widgets/pedido_card.dart';

class MotorizadoDashboardScreen extends ConsumerStatefulWidget {
  const MotorizadoDashboardScreen({super.key});

  @override
  ConsumerState<MotorizadoDashboardScreen> createState() =>
      _MotorizadoDashboardScreenState();
}

class _MotorizadoDashboardScreenState
    extends ConsumerState<MotorizadoDashboardScreen> {
  int _selectedIndex = 0;

  final List<Pedido> _pedidos = [
    Pedido(
      titulo: 'Entrega para Oficinas A&B',
      recojo: 'Almacén Central',
      entrega: 'Oficinas A&B',
      descripcionPaquete: 'Documentos y papelería',
      iconoPaquete: Icons.folder,
      status: PedidoStatus.pendiente,
    ),
    Pedido(
      titulo: 'Recogo de documentos importantes',
      recojo: 'Cliente X',
      entrega: 'Archivo General',
      descripcionPaquete: 'Documentos confidenciales',
      iconoPaquete: Icons.description,
      status: PedidoStatus.pendiente,
    ),
    Pedido(
      titulo: 'Entrega urgente - Zona Financiera',
      recojo: 'Sucursal Sur',
      entrega: 'Zona Financiera',
      descripcionPaquete: 'Paquete urgente',
      iconoPaquete: Icons.local_shipping,
      status: PedidoStatus.pendiente,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí iría la lógica para cambiar de pantalla
  }

  @override
  Widget build(BuildContext context) {
    // final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Pedidos',
          // Text('Estado: ${authState.workState ?? 'Desconocido'}'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bell),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Marcar Salida',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Marcar salida?'),
                  content: const Text(
                    '¿Estás seguro que deseas finalizar tu jornada?',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Confirmar'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await AttendanceService.marcarAsistencia(
                  context: context,
                  tipo: 'check-out',
                  onSuccess: () async {
                    Navigator.of(context).pop();
                    await ref.read(authNotifierProvider.notifier).fetchMe();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Salida registrada correctamente.'),
                      ),
                    );
                    setState(() {});
                  },
                );
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          return PedidoCard(pedido: _pedidos[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF97316),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.listUl),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.mapLocationDot),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clockRotateLeft),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.comments),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
