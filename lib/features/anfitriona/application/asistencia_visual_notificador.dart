import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/attendance_service.dart';

class AsistenciaVisualState {
  final bool isLoading;
  final bool puedeMarcarEntrada;
  final bool puedeMarcarSalida;
  final String accion;

  AsistenciaVisualState({
    this.isLoading = false,
    this.puedeMarcarEntrada = true,
    this.puedeMarcarSalida = false,
    this.accion = '',
  });

  AsistenciaVisualState copyWith({
    bool? isLoading,
    bool? puedeMarcarEntrada,
    bool? puedeMarcarSalida,
    String? accion,
  }) {
    return AsistenciaVisualState(
      isLoading: isLoading ?? this.isLoading,
      puedeMarcarEntrada: puedeMarcarEntrada ?? this.puedeMarcarEntrada,
      puedeMarcarSalida: puedeMarcarSalida ?? this.puedeMarcarSalida,
      accion: accion ?? this.accion,
    );
  }
}

class AsistenciaVisualNotifier extends StateNotifier<AsistenciaVisualState> {
  AsistenciaVisualNotifier() : super(AsistenciaVisualState());

  Future<void> marcarEntrada(BuildContext context) async {
    state = state.copyWith(isLoading: true, accion: 'entrada');
    await AttendanceService.marcarAsistencia(
      context: context,
      tipo: 'check-in',
      onSuccess: () async {
        state = state.copyWith(
          isLoading: false,
          puedeMarcarEntrada: false,
          puedeMarcarSalida: true,
          accion: '',
        );
      },
    );
  }

  Future<void> marcarSalida(BuildContext context) async {
    state = state.copyWith(isLoading: true, accion: 'salida');
    await AttendanceService.marcarAsistencia(
      context: context,
      tipo: 'check-out',
      onSuccess: () async {
        state = state.copyWith(
          isLoading: false,
          puedeMarcarEntrada: true,
          puedeMarcarSalida: false,
          accion: '',
        );
      },
    );
  }
}

final asistenciaVisualProvider =
    StateNotifierProvider<AsistenciaVisualNotifier, AsistenciaVisualState>(
      (ref) => AsistenciaVisualNotifier(),
    );
