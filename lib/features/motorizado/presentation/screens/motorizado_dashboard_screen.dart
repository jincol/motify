import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/pedido.dart';
import '../widgets/pedido_card.dart';

class MotorizadoDashboardScreen extends StatefulWidget {
  const MotorizadoDashboardScreen({super.key});

  @override
  State<MotorizadoDashboardScreen> createState() =>
      _MotorizadoDashboardScreenState();
}

class _MotorizadoDashboardScreenState extends State<MotorizadoDashboardScreen> {
  int _selectedIndex = 0;

  final List<Pedido> _pedidos = [
    Pedido(
      titulo: 'Entrega para Oficinas A&B',
      recojo: 'Almacén Central',
      entrega: 'Oficinas A&B',
      descripcionPaquete: 'Documentos y papelería',
      iconoPaquete: Icons.folder,
      status: PedidoStatus.pendiente,
    ),
    Pedido(
      titulo: 'Recogo de documentos importantes',
      recojo: 'Cliente X',
      entrega: 'Archivo General',
      descripcionPaquete: 'Documentos confidenciales',
      iconoPaquete: Icons.description,
      status: PedidoStatus.pendiente,
    ),
    Pedido(
      titulo: 'Entrega urgente - Zona Financiera',
      recojo: 'Sucursal Sur',
      entrega: 'Zona Financiera',
      descripcionPaquete: 'Paquete urgente',
      iconoPaquete: Icons.local_shipping,
      status: PedidoStatus.pendiente,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí iría la lógica para cambiar de pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Pedidos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bell),
            onPressed: () {
              // Lógica para notificaciones
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          return PedidoCard(pedido: _pedidos[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lógica para agregar un nuevo pedido
        },
        backgroundColor: const Color(0xFFF97316),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.listUl),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.mapLocationDot),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clockRotateLeft),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.comments),
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
