// lib/core/providers/location_tracking_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_location_service.dart';

/// Estado del tracking de ubicación
class LocationTrackingState {
  final bool isTracking;
  final String workState;
  final DateTime? lastUpdate;

  LocationTrackingState({
    required this.isTracking,
    required this.workState,
    this.lastUpdate,
  });

  LocationTrackingState copyWith({
    bool? isTracking,
    String? workState,
    DateTime? lastUpdate,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      workState: workState ?? this.workState,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Notifier para manejar el tracking de ubicación
class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  LocationTrackingNotifier()
    : super(LocationTrackingState(isTracking: false, workState: 'INACTIVO'));

  /// Iniciar tracking
  Future<void> startTracking({
    required int userId,
    required String workState,
    required String token,
  }) async {
    try {
      await BackgroundLocationService.startTracking(
        userId: userId,
        workState: workState,
        token: token,
      );

      state = state.copyWith(
        isTracking: true,
        workState: workState,
        lastUpdate: DateTime.now(),
      );

      print('🚀 Tracking iniciado desde provider: $workState');
    } catch (e) {
      print('❌ Error al iniciar tracking: $e');
      rethrow;
    }
  }

  /// Detener tracking
  Future<void> stopTracking() async {
    try {
      await BackgroundLocationService.stopTracking();

      state = state.copyWith(isTracking: false, workState: 'INACTIVO');

      print('⏹️ Tracking detenido desde provider');
    } catch (e) {
      print('❌ Error al detener tracking: $e');
      rethrow;
    }
  }

  /// Actualizar work_state (cambia la frecuencia automáticamente)
  Future<void> updateWorkState(String newWorkState, {int? userId, String? token}) async {
    // ✅ PERMITIR actualizar el work_state aunque isTracking sea false
    // porque el servicio de background puede estar corriendo independientemente
    try {
      // Si cambia a EN_RUTA, reiniciar servicio para que lea el nuevo pedido_id
      if (newWorkState == 'EN_RUTA' && userId != null && token != null) {
        print('🔄 Cambiando a EN_RUTA - reiniciando servicio GPS...');
        await BackgroundLocationService.restartTracking(
          userId: userId,
          workState: newWorkState,
          token: token,
        );
      } else {
        // Para otros estados, solo actualizar frecuencia
        await BackgroundLocationService.updateTrackingFrequency(newWorkState);
      }

      // Actualizar el estado del provider
      state = state.copyWith(
        workState: newWorkState,
        lastUpdate: DateTime.now(),
        isTracking: newWorkState != 'INACTIVO', // Activar tracking si no está inactivo
      );

      print('🔄 Work state actualizado: $newWorkState (isTracking: ${state.isTracking})');
    } catch (e) {
      print('❌ Error al actualizar work state: $e');
      rethrow;
    }
  }
}

/// Provider principal de tracking
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>(
      (ref) => LocationTrackingNotifier(),
    );
