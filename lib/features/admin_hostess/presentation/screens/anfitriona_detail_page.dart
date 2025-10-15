import 'package:flutter/material.dart';
import 'package:motify/core/models/user.dart';
import 'package:motify/core/widgets/user_attendance_history_screen.dart';
import 'package:motify/core/widgets/user_detail_app_bar.dart';
import 'package:motify/features/shared/application/attendance_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnfitrionaDetailPage extends ConsumerWidget {
  final User user;
  const AnfitrionaDetailPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceHistoryProvider(user.id));
    return Scaffold(
      appBar: const UserDetailAppBar(title: 'Detalle de Anfitriona'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const SizedBox(height: 20),
                attendanceAsync.when(
                  data: (attendances) {
                    final userAttendances =
                        attendances.where((a) => a.userId == user.id).toList()
                          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    final recentTwo = userAttendances.take(2).toList();
                    return _buildRecentActivitySection(recentTwo);
                  },

                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error cargando asistencias')),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(context, ref),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para la sección principal del perfil
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
                backgroundImage:
                    (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                backgroundColor: Colors.orange.shade100,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                    ? Text(
                        _getInitials(user.name ?? ''),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _capitalize(user.fullName ?? ''),
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

  // Widget para mostrar el estado del usuario
  Widget _buildStatusChip(String status, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(
        status,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            _buildInfoRow(Icons.email_outlined, user.email ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, user.username ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, user.phone ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Placa: ${user.placaUnidad ?? ''}',
            ),
          ],
        ),
      ),
    );
  }

  // Helper para crear filas de información
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade400, size: 20),
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

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return value
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  Widget _buildRecentActivitySection(List<Attendance> attendances) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Evidencias de Asistencia:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            if (attendances.isEmpty)
              const Text('Sin registros de asistencia recientes.'),
            ...attendances.map((a) {
              final localTime = a.timestamp.toLocal();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildActivityItem(
                  imageUrl: a.photoUrl.isNotEmpty
                      ? a.photoUrl
                      : 'https://placehold.co/80x80/f97316/ffffff?text=Foto',
                  title: a.type == 'check-in'
                      ? 'Entrada'
                      : a.type == 'check-out'
                      ? 'Salida'
                      : a.type,
                  subtitle:
                      '${localTime.day.toString().padLeft(2, '0')}/'
                      '${localTime.month.toString().padLeft(2, '0')}/'
                      '${localTime.year}, '
                      '${localTime.hour.toString().padLeft(2, '0')}:'
                      '${localTime.minute.toString().padLeft(2, '0')}',
                  location: 'Punto de Trabajo A, Miraflores',
                  isEntry: a.type == 'check-in',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper para crear items de actividad con mejor diseño
  Widget _buildActivityItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String location,
    required bool isEntry,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo, color: Colors.orange.shade400),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEntry ? Icons.login : Icons.logout,
                      size: 16,
                      color: isEntry ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                        ),
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
  }

  // Widget para los botones de acción mejorados
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.history, color: Colors.black54),
            label: const Text(
              'Ver Historial',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              ref.invalidate(attendanceHistoryProvider(user.id));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAttendanceHistoryScreen(
                    userId: user.id,
                    userName: user.fullName ?? 'Usuario',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              // TODO: Abrir chat con la anfitriona
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abriendo chat con anfitriona...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
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

  // Método para obtener las iniciales del nombre
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  // Método para obtener el texto del estado
  String _getStatusText(String? workState) {
    switch (workState) {
      case 'JORNADA_ACTIVA':
        return 'Presente';
      case 'INACTIVO':
        return 'Inactiva';
      case 'EN_RUTA':
        return 'En Ruta';
      default:
        return 'Sin Estado';
    }
  }

  // Método para obtener el color del estado
  Color _getStatusColor(String? workState) {
    switch (workState) {
      case 'JORNADA_ACTIVA':
        return Colors.green;
      case 'INACTIVO':
        return Colors.red;
      case 'EN_RUTA':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
