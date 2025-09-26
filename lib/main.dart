import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/application/auth_notifier.dart';
import 'features/auth/application/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/motorizado/presentation/screens/motorizado_dashboard_screen.dart';
import 'features/motorizado/presentation/screens/jornada_control_screen.dart';

void main() {
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
        print('DEBUG workState: ${authState.workState}');
        if (authState.workState == 'JORNADA_ACTIVA') {
          homeWidget = const MotorizadoDashboardScreen();
        } else {
          homeWidget = const JornadaControlScreen();
        }
      } else if (authState.role?.toLowerCase() == 'anfitriona') {
        homeWidget = const JornadaControlScreen();
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
        '/anfitrionaJornada': (context) =>
            JornadaControlScreen(), // para anfitriona
      },
    );
  }
}
