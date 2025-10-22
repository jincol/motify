import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:motify/core/widgets/panel_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/features/auth/application/auth_notifier.dart';
import 'package:motify/core/services/attendance_service.dart';
import 'package:motify/core/providers/pedido_provider.dart';
import 'package:motify/features/motorizado/presentation/screens/pedido_detail_screen.dart';
import 'package:motify/features/motorizado/presentation/screens/crear_pedido_screen.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí iría la lógica para cambiar de pantalla
  }

  @override
  Widget build(BuildContext context) {
    final pedidosAsync = ref.watch(pedidosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      drawer: const MainDrawer(),
      appBar: PanelAppBar(
        title: 'Mis Pedidos',
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.white,
            ),
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
                    Navigator.pushReplacementNamed(
                      context,
                      '/motorizadoJornada',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Salida registrada correctamente.'),
                      ),
                    );
                    setState(() {});
                  },
                  ref: ref,
                );
              }
            },
          ),
        ],
      ),
      body: pedidosAsync.when(
        data: (pedidos) {
          if (pedidos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes pedidos asignados',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pedidosProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PedidoDetailScreen(pedidoId: pedido.id),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  pedido.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: pedido.estado == 'pendiente'
                                      ? Colors.orange.shade100
                                      : pedido.estado == 'en_proceso'
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  pedido.estado.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: pedido.estado == 'pendiente'
                                        ? Colors.orange.shade700
                                        : pedido.estado == 'en_proceso'
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Código: ${pedido.codigoPedido}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remitente: ${pedido.nombreRemitente}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${pedido.paradas.length} paradas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error al cargar pedidos',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(pedidosProvider);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearPedidoScreen()),
          );
        },
        backgroundColor: const Color(0xFFF97316),
        tooltip: 'Crear nuevo pedido',
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Ruta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
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

// ---------------------------

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:motify/core/widgets/marcar_salida_button.dart';
// import 'package:motify/core/widgets/main_drawer.dart';
// import 'package:motify/core/widgets/panel_app_bar.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:motify/features/auth/application/auth_notifier.dart';
// import 'package:motify/core/services/attendance_service.dart';
// import 'package:motify/features/motorizado/presentation/screens/pedido_detail_screen.dart';
// import '../../models/pedido.dart';
// import '../widgets/pedido_card.dart';

// class MotorizadoDashboardScreen extends ConsumerStatefulWidget {
//   const MotorizadoDashboardScreen({super.key});

//   @override
//   ConsumerState<MotorizadoDashboardScreen> createState() =>
//       _MotorizadoDashboardScreenState();
// }

// class _MotorizadoDashboardScreenState
//     extends ConsumerState<MotorizadoDashboardScreen> {
//   int _selectedIndex = 0;

//   final List<Pedido> _pedidos = [
//     Pedido(
//       titulo: 'Entrega para Oficinas A&B',
//       recojo: 'Almacén Central',
//       entrega: 'Oficinas A&B',
//       descripcionPaquete: 'Documentos y papelería',
//       iconoPaquete: Icons.folder,
//       status: PedidoStatus.pendiente,
//     ),
//     Pedido(
//       titulo: 'Recogo de documentos importantes',
//       recojo: 'Cliente X',
//       entrega: 'Archivo General',
//       descripcionPaquete: 'Documentos confidenciales',
//       iconoPaquete: Icons.description,
//       status: PedidoStatus.pendiente,
//     ),
//     Pedido(
//       titulo: 'Entrega urgente - Zona Financiera',
//       recojo: 'Sucursal Sur',
//       entrega: 'Zona Financiera',
//       descripcionPaquete: 'Paquete urgente',
//       iconoPaquete: Icons.local_shipping,
//       status: PedidoStatus.pendiente,
//     ),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     // Aquí iría la lógica para cambiar de pantalla
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final authState = ref.watch(authNotifierProvider);
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F5F2),
//       drawer: const MainDrawer(),
//       appBar: PanelAppBar(
//         title: 'Mis Pedidos',
//         actions: [
//           IconButton(
//             icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const FaIcon(
//               FontAwesomeIcons.rightFromBracket,
//               color: Colors.white,
//             ),
//             tooltip: 'Marcar Salida',
//             onPressed: () async {
//               final confirm = await showDialog<bool>(
//                 context: context,
//                 builder: (ctx) => AlertDialog(
//                   title: const Text('¿Marcar salida?'),
//                   content: const Text(
//                     '¿Estás seguro que deseas finalizar tu jornada?',
//                   ),
//                   actions: [
//                     TextButton(
//                       child: const Text('Cancelar'),
//                       onPressed: () => Navigator.of(ctx).pop(false),
//                     ),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFF97316),
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 12,
//                         ),
//                       ),
//                       child: const Text('Confirmar'),
//                       onPressed: () => Navigator.of(ctx).pop(true),
//                     ),
//                   ],
//                 ),
//               );
//               if (confirm == true) {
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (_) =>
//                       const Center(child: CircularProgressIndicator()),
//                 );
//                 await AttendanceService.marcarAsistencia(
//                   context: context,
//                   tipo: 'check-out',
//                   onSuccess: () async {
//                     Navigator.of(context).pop();
//                     await ref.read(authNotifierProvider.notifier).fetchMe();
//                     Navigator.pushReplacementNamed(
//                       context,
//                       '/motorizadoJornada',
//                     );
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Salida registrada correctamente.'),
//                       ),
//                     );
//                     setState(() {});
//                   },
//                   ref: ref,
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: _pedidos.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => PedidoDetailScreen(
//                     pedidoId:
//                         index +
//                         1, // Por ahora usa el índice, luego usarás el ID real
//                   ),
//                 ),
//               );
//             },
//             child: PedidoCard(pedido: _pedidos[index]),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {},
//         backgroundColor: const Color(0xFFF97316),
//         child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
//           BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Ruta'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'Historial',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat_bubble_outline),
//             label: 'Chat',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: const Color(0xFFF97316),
//         unselectedItemColor: Colors.grey[600],
//         onTap: _onItemTapped,
//         showUnselectedLabels: true,
//         type: BottomNavigationBarType.fixed,
//       ),
//     );
//   }
// }
