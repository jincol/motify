import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class RiderForm extends StatefulWidget {
  final String title;
  final void Function(Map<String, dynamic> data)? onSubmit;

  const RiderForm({super.key, required this.title, this.onSubmit});

  @override
  State<RiderForm> createState() => _RiderFormState();
}

class _RiderFormState extends State<RiderForm> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _placaController = TextEditingController();
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nombre': _nameController.text,
        'apellido': _lastNameController.text,
        'email': _emailController.text,
        'usuario': _userController.text,
        'contrasena': _passwordController.text,
        'telefono': _phoneController.text,
        'placa_unidad': _placaController.text,
        'foto': _profileImage,
      };
      print('DEBUG placa_unidad: \'${_placaController.text}\'');
      print('DEBUG data enviada: $data');
      widget.onSubmit?.call(data);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.title} guardado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const lightGrayColor = Color(0xFFE5E7EB);
    const darkTextColor = Color(0xFF1F2937);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Foto de perfil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: lightGrayColor,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(
                            LucideIcons.user,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      'Subir Foto',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Campos de texto
            _buildTextField(controller: _nameController, label: 'Nombre'),
            const SizedBox(height: 16),
            _buildTextField(controller: _lastNameController, label: 'Apellido'),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, label: 'Email'),
            const SizedBox(height: 16),
            _buildTextField(controller: _userController, label: 'Usuario'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono (Opcional)',
              isOptional: true,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _placaController,
              label: 'AB-123 (Opcional)',
              isOptional: true,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: lightGrayColor),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: darkTextColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    bool isOptional = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
