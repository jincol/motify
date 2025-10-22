import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:motify/core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_repository.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String _channelId = 'motify_location_tracking';
  static const String _channelName = 'Motify GPS Tracking';
  static const int _notificationId = 888;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Tracking de ubicación en tiempo real',
      importance:
          Importance.high, // Cambiado de low a high para que sea visible
      playSound: false, // Sin sonido para no molestar
      enableVibration: false, // Sin vibración
      showBadge: true, // Mostrar badge en el ícono de la app
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configurar servicio
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Motify GPS',
        initialNotificationContent: 'Tracking desactivado',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Configurar servicio como foreground para Android
    // Usamos try-catch porque no podemos importar AndroidServiceInstance
    // sin causar conflicto de isolates
    try {
      // Intentar establecer como foreground service (solo Android)
      // ignore: avoid_dynamic_calls
      (service as dynamic).setAsForegroundService();

      service.on('setAsForeground').listen((event) {
        // ignore: avoid_dynamic_calls
        (service as dynamic).setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        // ignore: avoid_dynamic_calls
        (service as dynamic).setAsBackgroundService();
      });
    } catch (e) {
      // iOS o error - continuar sin foreground service
      print('⚠️ No se pudo configurar como foreground service: $e');
    }

    // Escuchar comandos de la app
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    service.on('updateFrequency').listen((event) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tracking_interval_seconds', event?['seconds'] ?? 300);
    });

    service.on('updateNotification').listen((event) async {
      final workState = event?['workState'] ?? 'INACTIVO';
      final timestamp =
          event?['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;

      print('🔔 Listener recibió workState: $workState');
      print('🔔 Event completo: $event');

      _updateNotification(
        service,
        workState: workState,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    });

    // Esperar un momento para que se guarden las SharedPreferences
    await Future.delayed(const Duration(seconds: 2));

    // Loop principal de captura de GPS
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // Verificar que hay datos de usuario antes de capturar
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId == null) {
          // Si no hay usuario, esperar al siguiente ciclo
          return;
        }

        // Verificar si es foreground service (solo Android)
        // ignore: avoid_dynamic_calls
        final isForeground = await (service as dynamic).isForegroundService();
        if (isForeground == true) {
          await _captureAndSendLocation(service);
        }
      } catch (e) {
        // iOS o error - ejecutar de todas formas
        await _captureAndSendLocation(service);
      }
    });
  }

  /// Capturar ubicación y enviar al backend
  @pragma('vm:entry-point')
  static Future<void> _captureAndSendLocation(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final intervalSeconds = prefs.getInt('tracking_interval_seconds') ?? 3600;
      final lastSentTimestamp = prefs.getInt('last_location_sent') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final workState = prefs.getString('work_state') ?? 'INACTIVO';

      if (workState == 'INACTIVO') {
        print('⏸️ Estado INACTIVO, deteniendo tracking');
        await BackgroundLocationService.stopTracking();
        return;
      }

      if (now - lastSentTimestamp < intervalSeconds) {
        return;
      }

      // Capturar ubicación
      final position = await LocationService.getCurrentLocation();

      // Obtener datos del usuario
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('auth_token');

      // Si no hay userId o token válido, detener el tracking y limpiar prefs
      if (userId == null || token == null) {
        print(
          '⚠️ Usuario no autenticado o token ausente, deteniendo tracking y limpiando prefs',
        );
        try {
          await prefs.remove('user_id');
          await prefs.remove('auth_token');
          await prefs.remove('tracking_interval_seconds');
          await prefs.remove('last_location_sent');
          await prefs.remove('work_state');
        } catch (_) {}

        // Intentar detener el servicio de forma segura
        try {
          service.invoke('stopService');
        } catch (e) {
          try {
            service.stopSelf();
          } catch (_) {}
        }

        return;
      }

      // Enviar al backend
      final success = await LocationRepository.sendLocation(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        workState: workState,
        speed: position.speed,
        heading: position.heading,
        token: token,
      );

      if (success) {
        await prefs.setInt('last_location_sent', now);

        // Actualizar notificación
        _updateNotification(
          service,
          workState: workState,
          lastUpdate: DateTime.now(),
        );

        print(
          '✅ Ubicación enviada: ${position.latitude}, ${position.longitude}',
        );
      } else {
        // En caso de fallo (ej. 401), no actualizamos last_location_sent
        print('❌ Error al enviar ubicación (sendLocation devolvió false)');
      }
    } catch (e) {
      print('❌ Error en captura GPS: $e');
    }
  }

  /// Actualizar notificación
  @pragma('vm:entry-point')
  static void _updateNotification(
    ServiceInstance service, {
    required String workState,
    required DateTime lastUpdate,
  }) {
    try {
      String statusText;
      switch (workState) {
        case 'EN_RUTA':
          statusText = '🚚 En ruta - GPS cada 30s';
          break;
        case 'JORNADA_ACTIVA':
          statusText = '✅ Jornada activa - GPS cada 5min';
          break;
        default:
          statusText = '⏸️ Inactivo';
      }

      final timeText =
          '${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}';

      // Actualizar notificación (solo Android)
      // ignore: avoid_dynamic_calls
      (service as dynamic).setForegroundNotificationInfo(
        title: 'Motify GPS Tracking',
        content: '$statusText\nÚltima actualización: $timeText',
      );

      print('🔔 Notificación actualizada: $statusText');
    } catch (e) {
      // iOS o error - ignorar
      print('⚠️ No se pudo actualizar notificación: $e');
    }
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> startTracking({
    required int userId,
    required String workState,
    required String token,
  }) async {
    // Solo iniciar tracking si el estado es activo
    if (workState == 'INACTIVO') {
      print('⏸️ No se inicia tracking en estado INACTIVO');
      return;
    }

    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();

    // Guardar datos del usuario
    await prefs.setInt('user_id', userId);
    await prefs.setString('work_state', workState);
    await prefs.setString('auth_token', token);

    // Configurar intervalo según work_state
    int intervalSeconds;
    switch (workState) {
      case 'EN_RUTA':
        intervalSeconds = 30;
        break;
      case 'JORNADA_ACTIVA':
        intervalSeconds = 25;
        break;
      default:
        intervalSeconds = 600; // 10 minutos
    }
    await prefs.setInt('tracking_interval_seconds', intervalSeconds);

    // Iniciar servicio
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      // Esperar a que el servicio se inicie completamente
      await Future.delayed(const Duration(milliseconds: 500));
    }

    service.invoke('updateFrequency', {'seconds': intervalSeconds});

    // Esperar un momento antes de actualizar la notificación
    await Future.delayed(const Duration(milliseconds: 200));

    print('🚀 Invocando updateNotification con workState: $workState');

    service.invoke('updateNotification', {
      'workState': workState,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print('🚀 Tracking iniciado: $workState cada ${intervalSeconds}s');
  }

  /// Detener tracking
  @pragma('vm:entry-point')
  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    // Intentar señal para detener
    try {
      service.invoke('stopService');
    } catch (_) {
      // ignore
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('work_state');
    await prefs.remove('tracking_interval_seconds');
    await prefs.remove('auth_token');
    await prefs.remove('last_location_sent');

    print('⏹️ Tracking detenido y prefs limpiadas');
  }

  @pragma('vm:entry-point')
  static Future<void> updateTrackingFrequency(String workState) async {
    // Si el estado es INACTIVO, detener tracking
    if (workState == 'INACTIVO') {
      print(
        '⏸️ updateTrackingFrequency: Deteniendo tracking por estado INACTIVO',
      );
      await BackgroundLocationService.stopTracking();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_state', workState);

    int intervalSeconds;
    switch (workState) {
      case 'EN_RUTA':
        intervalSeconds = 30;
        break;
      case 'JORNADA_ACTIVA':
        intervalSeconds = 25;
        break;
      default:
        intervalSeconds = 600;
    }
    await prefs.setInt('tracking_interval_seconds', intervalSeconds);

    final service = FlutterBackgroundService();
    service.invoke('updateFrequency', {'seconds': intervalSeconds});

    print('🔄 Frecuencia actualizada: $workState cada ${intervalSeconds}s');
  }
}
