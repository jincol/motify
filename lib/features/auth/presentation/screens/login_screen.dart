import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth_notifier.dart';
import '../widgets/custom_text_field.dart';
import '../../../../core/widgets/wave_clipper.dart';
import '../../application/auth_state.dart';

final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);

    if (authState.authStatus == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF388E3C)),
                SizedBox(width: 12),
                Expanded(child: Text('¡Bienvenido! Login exitoso.')),
              ],
            ),
            backgroundColor: const Color(0xFFE8F5E9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        if (authState.role == 'motorizado') {
          Navigator.pushReplacementNamed(context, '/motorizadoJornada');
        } else if (authState.role == 'anfitriona') {
          Navigator.pushReplacementNamed(context, '/anfitrionaJornada');
        }
        if (authState.role == 'admin_motorizado') {
          Navigator.pushReplacementNamed(context, '/adminMotorizadoDashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }

    if (authState.authStatus == AuthStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Usuario o contraseña incorrectos')),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 36, 35, 35),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          ref.read(authNotifierProvider.notifier).resetState();
        }
      });
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3E0), Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 40),
              CustomTextField(
                hint: 'Usuario',
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                isPassword: true,
                showPassword: _showPassword,
                onTogglePassword: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                controller: passwordController,
              ),
              const SizedBox(height: 10),
              _buildForgotPassword(),
              const SizedBox(height: 30),
              _buildLoginButton(authNotifier),
              const Spacer(),
              _buildSignUpLink(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB74D), Color(0xFFFB8C00)],
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.4,
            child: Image.asset(
              'assets/images/logo_oa.png',
              height: 185,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {},
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthNotifier authNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final usuario = emailController.text.trim();
            final contrasena = passwordController.text.trim();
            authNotifier.login(usuario, contrasena);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFB8C00)],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
