import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../domain/models/rider.dart';
import '../widgets/rider_card.dart';

class AdminTeamScreen extends StatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  State<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends State<AdminTeamScreen> {
  RiderStatus? _activeFilter;

  final List<Rider> _allRiders = [
    Rider(
      id: '1',
      name: 'Carlos Vega',
      status: RiderStatus.enRuta,
      orderId: '5421',
      avatarUrl: 'https://placehold.co/48x48/FFEDD5/F97316?text=CV',
    ),
    Rider(
      id: '2',
      name: 'Juan Pérez',
      status: RiderStatus.jornadaActiva,
      avatarUrl: 'https://placehold.co/48x48/FFEDD5/F97316?text=JP',
    ),
    Rider(
      id: '3',
      name: 'Ana Morales',
      status: RiderStatus.inactivo,
      avatarUrl: 'https://placehold.co/48x48/FFEDD5/F97316?text=AM',
    ),
    Rider(
      id: '4',
      name: 'Luis Gomez',
      status: RiderStatus.inactivo,
      avatarUrl: 'https://placehold.co/48x48/FFEDD5/F97316?text=LG',
    ),
  ];
  List<Rider> _filteredRiders = [];

  @override
  void initState() {
    super.initState();
    _filteredRiders = List.from(_allRiders);
  }

  void _filterRiders(RiderStatus? status) {
    setState(() {
      _activeFilter = status;
      if (status == null) {
        _filteredRiders = List.from(_allRiders);
      } else {
        _filteredRiders = _allRiders
            .where((rider) => rider.status == status)
            .toList();
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Rider rider) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(
                  LucideIcons
                      .alignVerticalSpaceAround, // Usa alertCircle o alertOctagon
                  color: Color(0xFFDC2626),
                ),
              ),
              SizedBox(height: 16),
              Text('Eliminar Motorizado', textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar a ${rider.name}? Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        _allRiders.removeWhere((r) => r.id == rider.id);
                        _filterRiders(_activeFilter);
                      });
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${rider.name} ha sido eliminado.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openRiderForm({Rider? rider}) {
    final String title = rider == null
        ? 'Agregando Motorizado'
        : 'Editando a ${rider.name}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(title), backgroundColor: const Color(0xFFF97316)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        title: const Text(
          'Gestión de Equipo',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                children: <Widget>[
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _activeFilter == null,
                    onSelected: (bool selected) => _filterRiders(null),
                    selectedColor: const Color(0xFFF97316).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeFilter == null
                          ? const Color(0xFFF97316)
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilterChip(
                    label: const Text('En Ruta'),
                    selected: _activeFilter == RiderStatus.enRuta,
                    onSelected: (bool selected) =>
                        _filterRiders(RiderStatus.enRuta),
                    selectedColor: const Color(0xFFF97316).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeFilter == RiderStatus.enRuta
                          ? const Color(0xFFF97316)
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Jornada Activa'),
                    selected: _activeFilter == RiderStatus.jornadaActiva,
                    onSelected: (bool selected) =>
                        _filterRiders(RiderStatus.jornadaActiva),
                    selectedColor: const Color(0xFFF97316).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeFilter == RiderStatus.jornadaActiva
                          ? const Color(0xFFF97316)
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Inactivos'),
                    selected: _activeFilter == RiderStatus.inactivo,
                    onSelected: (bool selected) =>
                        _filterRiders(RiderStatus.inactivo),
                    selectedColor: const Color(0xFFF97316).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeFilter == RiderStatus.inactivo
                          ? const Color(0xFFF97316)
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filteredRiders.length,
              itemBuilder: (context, index) {
                final rider = _filteredRiders[index];
                return RiderCard(
                  rider: rider,
                  onEdit: () => _openRiderForm(rider: rider),
                  onDelete: () => _showDeleteConfirmation(context, rider),
                  onView: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
