import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/ruta_map_widget.dart';

class RutaFullscreenScreen extends StatefulWidget {
  const RutaFullscreenScreen({super.key});

  @override
  State<RutaFullscreenScreen> createState() => _RutaFullscreenScreenState();
}

class _RutaFullscreenScreenState extends State<RutaFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado y navegación
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // Restaurar barras del sistema
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RutaMapWidget(
        isFullscreen: true,
        onToggleFullscreen: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
