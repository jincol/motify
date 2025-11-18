import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motify/core/providers/group_locations_provider.dart';

/// Bottom sheet para seleccionar qué pedido del día mostrar en el mapa
class OrderSelectionBottomSheet extends ConsumerWidget {
  final int courierId;
  final String courierName;
  final Function(int orderId) onOrderSelected;

  const OrderSelectionBottomSheet({
    Key? key,
    required this.courierId,
    required this.courierName,
    required this.onOrderSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(todayOrdersProvider(courierId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.motorcycle, color: Colors.blue.shade700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courierName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pedidos de hoy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(),

          // Contenido
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sin pedidos hoy',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Este motorizado aún no tiene pedidos asignados para hoy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(context, order);
                },
              );
            },
            loading: () => Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar pedidos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id'] as int;
    final code = order['code'] as String? ?? 'Sin código';
    final title = order['title'] as String? ?? 'Sin título';
    final status = order['status'] as String? ?? 'unknown';
    final createdAt = order['created_at'] as String?;
    final stops = order['stops'] as List? ?? [];

    // Determinar color e ícono según estado
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'PENDIENTE';
        break;
      case 'in_process':
        statusColor = Colors.blue;
        statusIcon = Icons.directions_run;
        statusText = 'EN PROCESO';
        break;
      case 'finished':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'FINALIZADO';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = status.toUpperCase();
    }

    // Formatear fecha
    String timeText = '';
    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt);
        timeText = DateFormat('HH:mm').format(dateTime);
      } catch (e) {
        timeText = 'Hora desconocida';
      }
    }

    // Información de paradas
    final pickupStop = stops.firstWhere(
      (s) => s['type'] == 'pickup',
      orElse: () => null,
    );
    final deliveryStop = stops.firstWhere(
      (s) => s['type'] == 'delivery',
      orElse: () => null,
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          onOrderSelected(orderId);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: código y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.receipt, size: 20, color: Colors.grey[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            code,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Título del pedido
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (timeText.isNotEmpty) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],

              // Información de paradas
              if (pickupStop != null || deliveryStop != null) ...[
                SizedBox(height: 12),
                if (pickupStop != null) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickupStop['address'] ?? 'Sin dirección',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pickupStop['confirmed'] == true)
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                ],
                if (deliveryStop != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.flag, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deliveryStop['address'] ?? 'Sin dirección',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (deliveryStop['confirmed'] == true)
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                ],
              ],

              SizedBox(height: 12),

              // Botón Ver en mapa
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onOrderSelected(orderId);
                  },
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('Ver en mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
