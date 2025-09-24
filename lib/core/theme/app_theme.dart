import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    primarySwatch: Colors.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    // Puedes añadir más personalizaciones del tema aquí
    // textTheme: ...,
    // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange).copyWith(
    //   secondary: Colors.amber, // Ejemplo
    // ),
  );
});

class AppTheme {
  static const Color cardBackground = Colors.white;
  static const Color darkText = Colors.black87;
  static const Color primaryOrange = Colors.orange;
}
