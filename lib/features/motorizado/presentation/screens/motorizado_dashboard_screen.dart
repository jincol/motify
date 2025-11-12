import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:motify/core/widgets/main_drawer.dart';
import 'package:motify/core/widgets/panel_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/services/attendance_service.dart';
import 'package:motify/core/providers/pedido_provider.dart';
import 'package:motify/features/motorizado/presentation/screens/pedido_detail_screen.dart';
import 'package:motify/features/motorizado/presentation/screens/crear_pedido_screen.dart';
import 'package:motify/features/motorizado/presentation/screens/ruta_fullscreen_screen.dart';
import 'package:motify/features/motorizado/presentation/widgets/ruta_map_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotorizadoDashboardScreen extends ConsumerStatefulWidget {
  const MotorizadoDashboardScreen({super.key});

  @override
  ConsumerState<MotorizadoDashboardScreen> createState() =>
      _MotorizadoDashboardScreenState();
}

class _MotorizadoDashboardScreenState
    extends ConsumerState<MotorizadoDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sincronizar pedido_id al cargar el dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCurrentPedidoId();
    });
  }

  /// Sincroniza el pedido_id activo con SharedPreferences
  Future<void> _syncCurrentPedidoId() async {
    try {
      final pedidosAsync = ref.read(pedidosProvider);
      
      pedidosAsync.whenData((pedidos) async {
        if (pedidos.isEmpty) {
          print('⚠️ No hay pedidos para sincronizar');
          return;
        }
        
        print('🔄 Sincronizando current_pedido_id...');
        
        // Buscar el pedido activo (in_process primero, luego pending)
        final pedidoActivo = pedidos.firstWhere(
          (p) => p.estado == 'in_process',
          orElse: () => pedidos.firstWhere(
            (p) => p.estado == 'pending',
            orElse: () => pedidos.first,
          ),
        );
        
        final prefs = await SharedPreferences.getInstance();
        final currentPedidoId = prefs.getInt('current_pedido_id');
        
        if (currentPedidoId != pedidoActivo.id) {
          await prefs.setInt('current_pedido_id', pedidoActivo.id);
          print('✅ current_pedido_id sincronizado: ${currentPedidoId} → ${pedidoActivo.id}');
        } else {
          print('✅ current_pedido_id ya está sincronizado: ${pedidoActivo.id}');
        }
      });
    } catch (e) {
      print('⚠️ Error sincronizando pedido_id: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para construir el body según el tab seleccionado
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildPedidosTab();
      case 1:
        return RutaMapWidget(
          onToggleFullscreen: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RutaFullscreenScreen(),
              ),
            );
          },
        );
      case 2:
        return const Center(
          child: Text(
            'Historial (Próximamente)',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      case 3:
        return const Center(
          child: Text(
            'Chat (Próximamente)',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      default:
        return _buildPedidosTab();
    }
  }

  // Tab de Pedidos (contenido original)
  Widget _buildPedidosTab() {
    final pedidosAsync = ref.watch(pedidosProvider);

    return pedidosAsync.when(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar título según tab seleccionado
    String appBarTitle = 'Mis Pedidos';
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Mis Pedidos';
        break;
      case 1:
        appBarTitle = 'Mi Ruta';
        break;
      case 2:
        appBarTitle = 'Historial';
        break;
      case 3:
        appBarTitle = 'Chat';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      drawer: const MainDrawer(),
      appBar: PanelAppBar(
        title: appBarTitle,
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
                  onSuccess: () {
                    // NO hacer nada aquí, el AttendanceService ya se encarga
                    // de actualizar el authState, y el código después del
                    // await se ejecutará automáticamente
                  },
                  ref: ref,
                );
                
                // Este código se ejecuta después de que AttendanceService termine
                // Cerrar el loading dialog si sigue abierto
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                
                // Navegar a la pantalla de jornada
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/motorizadoJornada');
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CrearPedidoScreen()),
                );
              },
              backgroundColor: const Color(0xFFF97316),
              tooltip: 'Crear nuevo pedido',
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            )
          : null,
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
