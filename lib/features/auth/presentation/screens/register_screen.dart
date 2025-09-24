import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerWidget {
  // Cambiado a ConsumerWidget
  const RegisterScreen({super.key});

  // Controllers para los TextFields
  // final _fullNameController = TextEditingController();
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  // final _confirmPasswordController = TextEditingController();  // final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Añadido WidgetRef
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Usuario"),
        backgroundColor: Theme.of(
          context,
        ).primaryColor, // Usar el color primario del tema
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // child: Form( // Envuelve en un Form para validación
          //   key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Nombre completo",
                icon: Icons.person,
                // controller: _fullNameController,
                // validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Correo electrónico",
                icon: Icons.email,
                // controller: _emailController,
                // validator: (value) => value!.isEmpty ? "Campo requerido" : null, // Añadir validación de email
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Contraseña",
                icon: Icons.lock,
                isPassword: true,
                // controller: _passwordController,
                // validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Confirmar contraseña",
                icon: Icons.lock,
                isPassword: true,
                // controller: _confirmPasswordController,
                // validator: (value) {
                //   if (value!.isEmpty) return "Campo requerido";
                //   if (value != _passwordController.text) return "Las contraseñas no coinciden";
                //   return null;
                // },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // if (_formKey.currentState!.validate()) {
                    //   // Lógica de registro
                    //   // String fullName = _fullNameController.text;
                    //   // String email = _emailController.text;
                    //   // String password = _passwordController.text;
                    //   // ref.read(authControllerProvider.notifier).register(...);
                    //   print("Botón Registrar presionado. Implementar lógica.");
                    // }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor, // Usar color del tema
                  ),
                  child: const Text(
                    "Registrar",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          // ),
        ),
      ),
    );
  }
}
