import 'package:flutter/material.dart';

// Modelo de asistencia reutilizable
class Attendance {
  final String tipo; // 'entrada' o 'salida'
  final String hora; // Ej: '09:01 AM'
  final DateTime fecha;
  Attendance({required this.tipo, required this.hora, required this.fecha});
}

// (Opcional) Datos de ejemplo para pruebas
final List<Attendance> exampleAttendances = [
  Attendance(tipo: 'Entrada', hora: '09:01 AM', fecha: DateTime.now()),
  Attendance(
    tipo: 'Salida',
    hora: '06:05 PM',
    fecha: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Attendance(
    tipo: 'Entrada',
    hora: '08:58 AM',
    fecha: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// Widget genérico para mostrar historial de asistencias
class AttendanceHistoryList extends StatelessWidget {
  final List<Attendance> attendances;
  final void Function(Attendance) onDetail;

  const AttendanceHistoryList({
    Key? key,
    required this.attendances,
    required this.onDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupa asistencias por día
    Map<String, List<Attendance>> grouped = {};
    for (var a in attendances) {
      final key = _formatDate(a.fecha);
      grouped.putIfAbsent(key, () => []).add(a);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descendente

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        for (final day in sortedKeys) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
          ...grouped[day]!.map(
            (asistencia) => _AsistenciaCard(
              tipo: asistencia.tipo,
              hora: asistencia.hora,
              isEntrada: asistencia.tipo.toLowerCase() == 'entrada',
              onDetailPressed: () => onDetail(asistencia),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'HOY, ${_dateString(date)}';
    }
    final ayer = now.subtract(const Duration(days: 1));
    if (date.year == ayer.year &&
        date.month == ayer.month &&
        date.day == ayer.day) {
      return 'AYER, ${_dateString(date)}';
    }
    return _dateString(date);
  }

  String _dateString(DateTime date) {
    final months = [
      '',
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${date.day.toString().padLeft(2, '0')} DE ${months[date.month]} ${date.year}';
  }
}

// Card de asistencia reutilizable
class _AsistenciaCard extends StatelessWidget {
  final String tipo;
  final String hora;
  final bool isEntrada;
  final VoidCallback onDetailPressed;
  static const Color brandOrange = Color(0xFFF97316);

  const _AsistenciaCard({
    required this.tipo,
    required this.hora,
    required this.isEntrada,
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isEntrada
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEntrada ? Icons.login : Icons.logout,
                    color: isEntrada
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 28.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      hora,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            OutlinedButton(
              onPressed: onDetailPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: brandOrange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              child: const Text(
                'Ver Detalle',
                style: TextStyle(
                  color: brandOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
