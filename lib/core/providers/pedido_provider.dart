import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pedido_model.dart';
import '../services/pedido_service.dart';

final pedidosProvider = FutureProvider<List<PedidoModel>>((ref) async {
  return await PedidoService.getPedidosMotorizado();
});

final pedidoDetailProvider = StateProvider.family<PedidoModel?, int>((
  ref,
  pedidoId,
) {
  final pedidosAsync = ref.watch(pedidosProvider);
  return pedidosAsync.whenData((pedidos) {
    return pedidos.firstWhere((p) => p.id == pedidoId);
  }).value;
});
