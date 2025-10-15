import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/models/user.dart';
import 'package:motify/features/shared/application/attendance_history_provider.dart';
import 'package:motify/core/widgets/user_attendance_history_screen.dart';

class MotorizadoDetailPage extends ConsumerWidget {
  final User user;
  const MotorizadoDetailPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceHistoryProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Detalle de Motorizado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildMetricsSection(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                attendanceAsync.when(
                  data: (attendances) {
                    final recentTwo =
                        (attendances.toList()..sort(
                              (a, b) => b.timestamp.compareTo(a.timestamp),
                            ))
                            .take(2)
                            .toList();
                    return _buildRecentActivitySection(recentTwo);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const Center(child: Text('Error cargando asistencias')),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(context, ref),
                const SizedBox(
                  height: 10,
                ), // Espacio adicional para evitar que se tape con la navegación
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 4),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                    ? Text(
                        _getInitials(user.name ?? ''),
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.black54,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _capitalize(user.fullName ?? user.username ?? ''),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusChip(
              _getStatusText(user.workState),
              _getStatusColor(user.workState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '12',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pedidos Hoy',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '25',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'min',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tiempo Promedio',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.email_outlined, user.email ?? 'Sin email'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, user.username ?? 'Sin usuario'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, user.phone ?? 'Sin teléfono'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.credit_card_outlined,
              'Placa: ${user.placaUnidad ?? 'Sin placa'}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.group_work_outlined,
              'Grupo: ${user.grupoId != null ? "Grupo #${user.grupoId}" : "Sin grupo"}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400]),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación Actual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const Divider(height: 24),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Mapa en Vivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(List<dynamic> attendances) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const Divider(height: 24),
            if (attendances.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay asistencias registradas',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ...attendances.map((attendance) {
                final localTime = attendance.timestamp.toLocal();
                final formattedDate =
                    '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
                final formattedTime =
                    '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
                final isEntrada = attendance.type.toLowerCase() == 'check-in';
                final title = isEntrada
                    ? 'Entrada de Jornada'
                    : 'Salida de Jornada';
                final subtitle = '$formattedDate, $formattedTime';
                final location =
                    'Lat: ${attendance.gpsLat?.toStringAsFixed(6) ?? 'N/A'}, Lng: ${attendance.gpsLng?.toStringAsFixed(6) ?? 'N/A'}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildActivityItem(
                    photoUrl: attendance.photoUrl,
                    title: title,
                    subtitle: subtitle,
                    location: location,
                  ),
                );
              }).toList(),
            if (attendances.isNotEmpty) ...[
              const Divider(height: 24, indent: 80, endIndent: 0),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 16),
                child: Text(
                  'Evidencias de Paradas (Pedido #54321):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              _buildActivityItem(
                photoUrl: null,
                title: 'Entrega Realizada',
                subtitle: '15/10/2025, 12:15 PM',
                location: 'Calle Las Begonias 456, San Isidro',
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                photoUrl: null,
                title: 'Recojo Realizado',
                subtitle: '15/10/2025, 11:30 AM',
                location: 'Almacén Central, Ate',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String? photoUrl,
    required String title,
    required String subtitle,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? Image.network(
                  photoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Foto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.history, color: Colors.black54),
            label: const Text(
              'Ver Historial',
              style: TextStyle(color: Colors.black54),
            ),
            onPressed: () {
              ref.invalidate(attendanceHistoryProvider(user.id));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAttendanceHistoryScreen(
                    userId: user.id,
                    userName: user.fullName ?? user.username,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: const Text(
              'Enviar Mensaje',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _getStatusText(String? workState) {
    if (workState == null) return 'Inactivo';
    switch (workState.toUpperCase()) {
      case 'EN_RUTA':
        return 'En Ruta';
      case 'JORNADA_ACTIVA':
        return 'Jornada Activa';
      case 'INACTIVO':
      default:
        return 'Inactivo';
    }
  }

  Color _getStatusColor(String? workState) {
    if (workState == null) return const Color(0xFF9CA3AF);
    switch (workState.toUpperCase()) {
      case 'EN_RUTA':
        return const Color(0xFF22C55E); // Verde
      case 'JORNADA_ACTIVA':
        return const Color(0xFFFACC15); // Amarillo
      case 'INACTIVO':
      default:
        return const Color(0xFF9CA3AF); // Gris
    }
  }
}
