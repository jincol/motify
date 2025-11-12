import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motify/core/models/pedido_model.dart';
import 'package:motify/core/providers/pedido_provider.dart';
import 'package:motify/core/providers/location_tracking_provider.dart';
import 'package:motify/core/services/pedido_service.dart';
import 'package:motify/core/services/photo_service.dart';
import 'package:motify/core/services/geocoding_service.dart';

class PedidoDetailScreen extends ConsumerStatefulWidget {
  final int pedidoId;

  const PedidoDetailScreen({Key? key, required this.pedidoId})
    : super(key: key);

  @override
  ConsumerState<PedidoDetailScreen> createState() => _PedidoDetailScreenState();
}

class _PedidoDetailScreenState extends ConsumerState<PedidoDetailScreen> {
  bool _isConfirming = false;

  Future<void> _crearYConfirmarParada(String tipo, PedidoModel pedido) async {
    if (_isConfirming) return;
    
    setState(() => _isConfirming = true);
    
    try {
      // 1. Tomar foto obligatoria
      final file = await PhotoService.takePhoto();
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Debes tomar una foto')),
        );
        setState(() => _isConfirming = false);
        return;
      }

      // 2. Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

            // 3. Subir foto y obtener URL
      final fotoUrl = await PhotoService.uploadPhoto(file);

      // 4. Obtener dirección real usando Google Geocoding API
      String descripcion;
      final addressResult = await GeocodingService.getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (addressResult != null && addressResult.isNotEmpty) {
        descripcion = addressResult;
        print('✅ Dirección obtenida: $descripcion');
      } else {
        // Fallback a coordenadas si falla el geocoding
        final lat = position.latitude.toStringAsFixed(6);
        final lng = position.longitude.toStringAsFixed(6);
        descripcion = '$lat, $lng';
        print('⚠️ Geocoding falló, usando coordenadas');
      }

      // 5. Fecha y hora actual
      final fechaHora = DateTime.now().toIso8601String();

      // 6. Llamada al servicio para crear y confirmar parada
      final nuevaParada = await PedidoService.crearYConfirmarParada(
        pedidoId: pedido.id,
        tipo: tipo,
        direccion: descripcion,
        fotoUrl: fotoUrl,
        gpsLat: position.latitude,
        gpsLng: position.longitude,
        fechaHora: fechaHora,
        notas: null,
      );

      if (nuevaParada == null) {
        throw Exception('No se pudo crear la parada');
      }

      // 7. Actualizar estado GPS según tipo de parada
      if (tipo == 'pickup') {
        // Primer recojo → cambiar a EN_RUTA y GUARDAR pedido_id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_pedido_id', pedido.id);
        print('✅ Guardado current_pedido_id: ${pedido.id}');
        
        await ref
            .read(locationTrackingProvider.notifier)
            .updateWorkState('EN_RUTA');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recojo confirmado\n📍 GPS tracking activado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (tipo == 'delivery') {
        // Verificar si TODAS las entregas de ESTE pedido están completas
        final pedidoActualizado = await ref.read(pedidosProvider.future);
        final pedidoRefrescado = pedidoActualizado.firstWhere(
          (p) => p.id == pedido.id,
          orElse: () => pedido,
        );

        final todasEntregasCompletas = pedidoRefrescado.paradas
            .where((p) => p.tipo == 'delivery')
            .every((p) => p.confirmado);

        if (todasEntregasCompletas) {
          // Verificar si hay otros pedidos activos
          final pedidosActivos = pedidoActualizado.where((p) =>
              p.id != pedido.id && p.estado == 'en_proceso').toList();
          
          print('🔍 DEBUG - Verificación de pedidos:');
          print('   Pedido actual ID: ${pedido.id}');
          print('   Total pedidos: ${pedidoActualizado.length}');
          print('   Pedidos activos (otros): ${pedidosActivos.length}');
          for (var p in pedidoActualizado) {
            print('   - Pedido ${p.id}: estado="${p.estado}" ${p.id == pedido.id ? "(ACTUAL)" : ""}');
          }
          
          final hayOtrosPedidosActivos = pedidosActivos.isNotEmpty;

          if (!hayOtrosPedidosActivos) {
            // Ya no hay pedidos activos → volver a JORNADA_ACTIVA y LIMPIAR pedido_id
            print('✅ Cambiando a JORNADA_ACTIVA (no hay más pedidos activos)');
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('current_pedido_id');
            print('✅ Limpiado current_pedido_id');
            
            await ref
                .read(locationTrackingProvider.notifier)
                .updateWorkState('JORNADA_ACTIVA');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pedido completado\n📍 Tracking cada 5 minutos'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // Hay otros pedidos activos → actualizar al siguiente pedido activo
            print('⚠️ Manteniendo EN_RUTA (hay ${pedidosActivos.length} pedidos activos)');
            
            final prefs = await SharedPreferences.getInstance();
            final siguientePedidoId = pedidosActivos.first.id;
            await prefs.setInt('current_pedido_id', siguientePedidoId);
            print('✅ Actualizado current_pedido_id a: $siguientePedidoId');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Pedido completado\n📦 Aún tienes ${pedidosActivos.length} pedido(s) activo(s)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega confirmada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // 8. Refrescar lista de pedidos para actualizar la UI
      ref.invalidate(pedidosProvider);
      ref.invalidate(pedidoDetailProvider(pedido.id));
      
      // Esperar a que el provider se actualice
      await Future.delayed(const Duration(milliseconds: 500));

      // 9. NO cerrar la pantalla - quedarse para mostrar el estado actualizado
      // Solo cerrar si es la última entrega del pedido
      if (tipo == 'delivery') {
        final pedidoActualizado = await ref.read(pedidosProvider.future);
        final pedidoRefrescado = pedidoActualizado.firstWhere(
          (p) => p.id == pedido.id,
          orElse: () => pedido,
        );
        
        final todasEntregasCompletas = pedidoRefrescado.paradas
            .where((p) => p.tipo == 'delivery')
            .every((p) => p.confirmado);
            
        if (todasEntregasCompletas) {
          // Solo cerrar si todas las entregas están completas
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
      // Si es recojo, NO cerrar - mostrar el botón de entrega
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _confirmarParada(ParadaModel parada, PedidoModel pedido) async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      // 1. Tomar foto obligatoria
      final file = await PhotoService.takePhoto();
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Debes tomar una foto')),
        );
        setState(() => _isConfirming = false);
        return;
      }

      // 2. Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Subir foto
      final fotoUrl = await PhotoService.uploadPhoto(file);

      // 4. Confirmar parada (sin dirección de entrega, solo GPS)
      final success = await PedidoService.confirmarParada(
        paradaId: parada.id,
        fotoUrl: fotoUrl,
        lat: position.latitude,
        lng: position.longitude,
        direccionEntrega: null,
        latEntrega: null,
        lngEntrega: null,
      );

      if (!success) {
        throw Exception('Error al confirmar parada');
      }

      // 5. Actualizar estado GPS según tipo de parada
      if (parada.tipo == 'pickup') {
        // Primer recojo → cambiar a EN_RUTA
        await ref
            .read(locationTrackingProvider.notifier)
            .updateWorkState('EN_RUTA');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recojo confirmado\n📍 GPS tracking activado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (parada.tipo == 'delivery') {
        // Verificar si TODAS las entregas de ESTE pedido están completas
        final pedidoActualizado = await ref.read(pedidosProvider.future);
        final pedidoRefrescado = pedidoActualizado.firstWhere(
          (p) => p.id == pedido.id,
          orElse: () => pedido,
        );

        final todasEntregasCompletas = pedidoRefrescado.paradas
            .where((p) => p.tipo == 'delivery')
            .every((p) => p.confirmado || p.id == parada.id);

        if (todasEntregasCompletas) {
          // Verificar si hay otros pedidos activos
          final pedidosActivos = pedidoActualizado.where((p) =>
              p.id != pedido.id && p.estado == 'en_proceso').toList();
          
          print('🔍 DEBUG _confirmarParada - Verificación de pedidos:');
          print('   Pedido actual ID: ${pedido.id}');
          print('   Total pedidos: ${pedidoActualizado.length}');
          print('   Pedidos activos (otros): ${pedidosActivos.length}');
          for (var p in pedidoActualizado) {
            print('   - Pedido ${p.id}: estado="${p.estado}" ${p.id == pedido.id ? "(ACTUAL)" : ""}');
          }
          
          final hayOtrosPedidosActivos = pedidosActivos.isNotEmpty;

          if (!hayOtrosPedidosActivos) {
            // Ya no hay pedidos activos → volver a JORNADA_ACTIVA
            print('✅ Cambiando a JORNADA_ACTIVA (no hay más pedidos activos)');
            await ref
                .read(locationTrackingProvider.notifier)
                .updateWorkState('JORNADA_ACTIVA');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pedido completado\n📍 Tracking cada 5 minutos'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            print('⚠️ Manteniendo EN_RUTA (hay ${pedidosActivos.length} pedidos activos)');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Pedido completado\n📦 Aún tienes ${pedidosActivos.length} pedido(s) activo(s)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega confirmada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // 6. Refrescar lista de pedidos
      ref.invalidate(pedidosProvider);

      // 7. Volver al dashboard
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = ref.watch(pedidoDetailProvider(widget.pedidoId));

    if (pedido == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Pedido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pedido.codigoPedido),
        backgroundColor: const Color(0xFFF97316),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del pedido
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Remitente: ${pedido.nombreRemitente}'),
                    if (pedido.telefono != null)
                      Text('Teléfono: ${pedido.telefono}'),
                    if (pedido.descripcion != null) ...[
                      const SizedBox(height: 8),
                      Text(pedido.descripcion!),
                    ],
                    if (pedido.instrucciones != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pedido.instrucciones!)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de paradas
            const Text(
              'Paradas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Lógica de botones según estado de las paradas
            ...() {
              // Verificar qué paradas existen
              final tieneRecojo = pedido.paradas.any((p) => p.tipo == 'pickup');
              final recojoConfirmado = pedido.paradas.any((p) => 
                p.tipo == 'pickup' && p.confirmado);
              final tieneEntrega = pedido.paradas.any((p) => p.tipo == 'delivery');
              
              List<Widget> botones = [];
              
              // Botón de Recojo: Solo si NO existe ninguna parada de recojo
              if (!tieneRecojo) {
                botones.add(
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text('Confirmar Recojo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _isConfirming ? null : () async {
                      await _crearYConfirmarParada('pickup', pedido);
                    },
                  ),
                );
                botones.add(const SizedBox(height: 12));
              }
              
              if (recojoConfirmado && !tieneEntrega) {
                botones.add(
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Confirmar Entrega'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _isConfirming ? null : () async {
                      await _crearYConfirmarParada('delivery', pedido);
                    },
                  ),
                );
                botones.add(const SizedBox(height: 12));
              }
              
              return botones;
            }(),

            // Mostrar paradas confirmadas con diseño mejorado
            ...pedido.paradas.map((parada) {
              final isRecojo = parada.tipo == 'pickup' || parada.tipo == 'recojo';
              final icon = isRecojo ? Icons.check_circle : Icons.location_on;
              final color = isRecojo ? Colors.blue : Colors.green;
              final tipoDisplay = isRecojo ? 'RECOJO' : 'ENTREGA';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipoDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parada.direccion ?? 'Ubicación GPS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check, color: color, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Confirmado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
