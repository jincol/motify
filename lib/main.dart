import 'package:flutter/material.dart';
import 'features/auth/application/auth_state.dart';
import 'features/auth/application/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/background_location_service.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/motorizado/presentation/screens/jornada_control_screen.dart';
import 'features/admin_motorized/presentation/screens/admin_main_screen.dart';
import 'features/admin_hostess/presentation/screens/admin_dashboard_screen.dart';
import 'features/motorizado/presentation/screens/motorizado_dashboard_screen.dart';
import 'package:motify/features/anfitriona/presentation/screens/asistencia_anfitriona_screen.dart';
import 'package:motify/features/admin_hostess/presentation/screens/admin_main_screen.dart';
// void main() {
//   runApp(const ProviderScope(child: MotifyApp()));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await BackgroundLocationService.initialize().timeout(
      const Duration(seconds: 5),
    );
    print('✅ Background location service inicializado');
  } catch (e) {
    print('⚠️ Error inicializando background service: $e');
    // La app continúa aunque falle el servicio
  }

  runApp(const ProviderScope(child: MotifyApp()));
}

class MotifyApp extends ConsumerWidget {
  const MotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    Widget homeWidget;
    if (authState.authStatus == AuthStatus.authenticated) {
      if (authState.role?.toLowerCase() == 'motorizado') {
        if (authState.workState == 'JORNADA_ACTIVA') {
          homeWidget = const MotorizadoDashboardScreen();
        } else {
          homeWidget = const JornadaControlScreen();
        }
      } else if (authState.role?.toLowerCase() == 'anfitriona') {
        homeWidget = const AsistenciaAnfitrionaScreen();
      } else if (authState.role?.toLowerCase() == 'admin_motorizado') {
        homeWidget = const AdminMotorizadoMainScreen();
        // } else if (authState.role?.toLowerCase() == 'super_admin') {
        //   homeWidget = const SuperAdminDashboardScreen();
      } else if (authState.role?.toLowerCase() == 'admin_anfitriona') {
        homeWidget = const AdminHostessMainScreen();
      } else {
        homeWidget = const HomeScreen();
      }
    } else if (authState.authStatus == AuthStatus.unauthenticated ||
        authState.authStatus == AuthStatus.error) {
      homeWidget = const LoginScreen();
    } else {
      homeWidget = const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return MaterialApp(
      title: 'Motify App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: homeWidget,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/motorizadoPage': (context) => const MotorizadoDashboardScreen(),
        '/motorizadoJornada': (context) => JornadaControlScreen(),
        '/anfitrionaJornada': (context) => AsistenciaAnfitrionaScreen(),
        '/adminMotorizadoDashboard': (context) =>
            const AdminMotorizadoMainScreen(),
        '/adminHostessDashboard': (context) =>
            const AdminHostessMainScreen(), // <-- Agrega esto
      },
    );
  }
}
