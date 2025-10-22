import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motify/core/models/pedido_model.dart';
import 'package:motify/core/models/place_suggestion.dart';
import 'package:motify/core/providers/pedido_provider.dart';
import 'package:motify/core/providers/location_tracking_provider.dart';
import 'package:motify/core/services/pedido_service.dart';
import 'package:motify/core/services/photo_service.dart';
import 'package:motify/core/widgets/address_autocomplete_field.dart';

class PedidoDetailScreen extends ConsumerStatefulWidget {
  final int pedidoId;

  const PedidoDetailScreen({Key? key, required this.pedidoId})
    : super(key: key);

  @override
  ConsumerState<PedidoDetailScreen> createState() => _PedidoDetailScreenState();
}

class _PedidoDetailScreenState extends ConsumerState<PedidoDetailScreen> {
  bool _isConfirming = false;

  Future<void> _confirmarParada(ParadaModel parada, PedidoModel pedido) async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      // 1. Tomar foto
      final file = await PhotoService.takePhoto();
      if (file == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes tomar una foto')));
        setState(() => _isConfirming = false);
        return;
      }

      // 2. Obtener ubicación
      final position = await Geolocator.getCurrentPosition();

      // 3. Si es RECOJO, pedir dirección de entrega con Places API
      String? direccionEntrega;
      double? latEntrega;
      double? lngEntrega;

      if (parada.tipo == 'recojo') {
        // Mostrar modal con autocomplete
        final resultado = await _mostrarModalDireccionEntrega();

        if (resultado == null) {
          // Usuario canceló
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Debes ingresar la dirección de entrega'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isConfirming = false);
          return;
        }

        direccionEntrega = resultado.description;
        latEntrega = resultado.latitude;
        lngEntrega = resultado.longitude;
      }

      // 4. Subir foto
      final fotoUrl = await PhotoService.uploadPhoto(file);

      // 5. Confirmar parada
      final success = await PedidoService.confirmarParada(
        paradaId: parada.id,
        fotoUrl: fotoUrl,
        lat: position.latitude,
        lng: position.longitude,
        direccionEntrega: direccionEntrega,
        latEntrega: latEntrega,
        lngEntrega: lngEntrega,
      );

      if (!success) {
        throw Exception('Error al confirmar parada');
      }

      // 6. Actualizar frecuencia GPS según tipo de parada
      if (parada.tipo == 'recojo') {
        // Primer recojo → cambiar a EN_RUTA
        await ref
            .read(locationTrackingProvider.notifier)
            .updateWorkState('EN_RUTA');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Recojo confirmado\n📍 Entrega: $direccionEntrega'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Entrega confirmada
        final todasEntregasCompletas = pedido.paradas
            .where((p) => p.tipo == 'entrega')
            .every((p) => p.confirmado || p.id == parada.id);

        if (todasEntregasCompletas) {
          // Última entrega → volver a JORNADA_ACTIVA
          await ref
              .read(locationTrackingProvider.notifier)
              .updateWorkState('JORNADA_ACTIVA');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pedido completado - Tracking cada 1 hora'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega confirmada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // 7. Refrescar lista de pedidos
      ref.invalidate(pedidosProvider);

      // 8. Volver al dashboard
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isConfirming = false);
    }
  }

  /// Muestra modal para ingresar dirección de entrega con Google Places
  Future<PlaceSuggestion?> _mostrarModalDireccionEntrega() async {
    final result = await showDialog<PlaceSuggestion>(
      context: context,
      barrierDismissible: false, // No cerrar al tocar fuera
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '¿A dónde entregarás?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: AddressAutocompleteField(
            hintText: 'Buscar dirección de entrega...',
            onPlaceSelected: (place) {
              Navigator.of(context).pop(place);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    return result;
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

            ...pedido.paradas.map((parada) {
              final isRecojo = parada.tipo == 'recojo';
              final icon = isRecojo ? Icons.upload : Icons.location_on;
              final color = isRecojo ? Colors.blue : Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: parada.confirmado
                        ? Colors.grey
                        : color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    '${parada.tipo.toUpperCase()} - ${parada.direccion}',
                    style: TextStyle(
                      decoration: parada.confirmado
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: parada.confirmado
                      ? const Text('✅ Confirmado')
                      : null,
                  trailing: parada.confirmado
                      ? null
                      : ElevatedButton(
                          onPressed: _isConfirming
                              ? null
                              : () => _confirmarParada(parada, pedido),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                          ),
                          child: _isConfirming
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Confirmar'),
                        ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
