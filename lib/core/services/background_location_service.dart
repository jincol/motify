import 'dart:ui';
import 'dart:async';
import 'location_repository.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:motify/core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: true,
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
      
      // También actualizar work_state si viene en el evento
      final workState = event?['workState'];
      if (workState != null) {
        await prefs.setString('work_state', workState);
        print('🔄 Service background actualizó work_state: $workState');
      }
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
    // Verificar cada 5 segundos para tener precisión en los intervalos
    Timer.periodic(const Duration(seconds: 5), (timer) async {
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

  @pragma('vm:entry-point')
  static Future<void> _captureAndSendLocation(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final intervalSeconds = prefs.getInt('tracking_interval_seconds') ?? 3600;
      final lastSentTimestamp = prefs.getInt('last_location_sent') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final workState = prefs.getString('work_state') ?? 'INACTIVO';

      // Debug logs
      final timeSinceLastSent = now - lastSentTimestamp;
      print('⏱️ Verificando envío GPS:');
      print('   Estado: $workState');
      print('   Intervalo configurado: ${intervalSeconds}s');
      print('   Tiempo desde último envío: ${timeSinceLastSent}s');
      print('   ¿Debe enviar?: ${timeSinceLastSent >= intervalSeconds}');

      if (workState == 'INACTIVO') {
        print('⏸️ Estado INACTIVO, deteniendo tracking');
        try {
          // Limpiar prefs primero
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user_id');
          await prefs.remove('work_state');
          await prefs.remove('tracking_interval_seconds');
          await prefs.remove('auth_token');
          await prefs.remove('last_location_sent');
          print('✅ Prefs limpiadas desde background loop');
          
          // Intentar detener el servicio
          try {
            service.stopSelf();
            print('✅ Servicio detenido desde background loop');
          } catch (e) {
            print('⚠️ Error deteniendo servicio: $e');
          }
        } catch (e) {
          print('⚠️ Error en proceso de limpieza: $e');
        }
        return;
      }

      if (now - lastSentTimestamp < intervalSeconds) {
        print('⏳ Aún no es tiempo de enviar (faltan ${intervalSeconds - timeSinceLastSent}s)');
        return;
      }

      print('📍 Capturando ubicación GPS...');
      final position = await LocationService.getCurrentLocation();
      print('✅ GPS capturado: ${position.latitude}, ${position.longitude}');

      final userId = prefs.getInt('user_id');
      final token = prefs.getString('auth_token');

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

      print('📤 Enviando ubicación al backend...');
      
      // Obtener pedido_id si existe (solo relevante cuando work_state es EN_RUTA)
      int? pedidoId;
      if (workState == 'EN_RUTA') {
        pedidoId = prefs.getInt('current_pedido_id');
        print('   📦 Pedido activo ID: $pedidoId');
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
        pedidoId: pedidoId,  // ✅ Incluir pedido_id si existe
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
          '✅ Ubicación enviada exitosamente: ${position.latitude}, ${position.longitude}',
        );
      } else {
        // En caso de fallo (ej. 401), no actualizamos last_location_sent
        print('❌ Error al enviar ubicación (sendLocation devolvió false)');
      }
    } catch (e, stackTrace) {
      print('❌ Error en captura GPS: $e');
      print('Stack trace: $stackTrace');
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
        intervalSeconds = 30; // 30 segundos
        break;
      case 'JORNADA_ACTIVA':
        intervalSeconds = 300; // 5 minutos
        break;
      default:
        intervalSeconds = 600; // 10 minutos
    }
    await prefs.setInt('tracking_interval_seconds', intervalSeconds);

    // IMPORTANTE: Resetear el timestamp para que envíe inmediatamente
    await prefs.setInt('last_location_sent', 0);

    print('🚀 Tracking configurado:');
    print('   UserId: $userId');
    print('   Estado: $workState');
    print('   Intervalo: ${intervalSeconds}s');

    // Iniciar servicio
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      // Esperar a que el servicio se inicie completamente
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Enviar comandos de forma segura
    try {
      service.invoke('updateFrequency', {'seconds': intervalSeconds});
      print('✅ Frecuencia inicial enviada al servicio');
    } catch (e) {
      print('⚠️ Error enviando updateFrequency inicial: $e');
    }

    // Esperar un momento antes de actualizar la notificación
    await Future.delayed(const Duration(milliseconds: 200));

    print('🚀 Invocando updateNotification con workState: $workState');

    try {
      service.invoke('updateNotification', {
        'workState': workState,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Notificación inicial enviada');
    } catch (e) {
      print('⚠️ Error enviando notificación inicial: $e');
    }

    print('✅ Tracking iniciado: $workState cada ${intervalSeconds}s');
  }

  /// Detener tracking
  @pragma('vm:entry-point')
  static Future<void> stopTracking() async {
    print('🛑 Iniciando stopTracking...');
    
    // Limpiar SharedPreferences primero
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('work_state');
    await prefs.remove('tracking_interval_seconds');
    await prefs.remove('auth_token');
    await prefs.remove('last_location_sent');
    print('✅ Prefs limpiadas');
    
    // Intentar detener el servicio de forma segura
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      print('ℹ️ Servicio corriendo: $isRunning');
      
      if (isRunning) {
        // Intentar con invoke primero (método más limpio)
        try {
          service.invoke('stopService');
          print('✅ Señal stopService enviada');
        } catch (e) {
          print('⚠️ Error en invoke stopService (ignorado): $e');
        }
      } else {
        print('ℹ️ Servicio ya estaba detenido');
      }
    } catch (e) {
      print('⚠️ Error al intentar detener servicio (ignorado): $e');
      // Las prefs ya están limpias, que es lo más importante
    }

    print('⏹️ Tracking detenido completamente');
  }

  /// Reiniciar tracking completamente (útil cuando cambia pedido_id)
  @pragma('vm:entry-point')
  static Future<void> restartTracking({
    required int userId,
    required String workState,
    required String token,
  }) async {
    print('🔄 INICIANDO REINICIO DE TRACKING...');
    print('   userId: $userId');
    print('   workState: $workState');
    print('   token: ${token.substring(0, 20)}...');
    
    // Detener servicio actual
    try {
      print('⏹️ Deteniendo servicio actual...');
      await stopTracking();
      print('✅ Servicio detenido, esperando 300ms...');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ Error deteniendo servicio (continuando): $e');
    }
    
    // Iniciar servicio nuevamente (leerá el nuevo pedido_id)
    print('🚀 Iniciando servicio nuevamente...');
    await startTracking(
      userId: userId,
      workState: workState,
      token: token,
    );
    
    print('✅ TRACKING REINICIADO COMPLETAMENTE');
  }

  @pragma('vm:entry-point')
  static Future<void> updateTrackingFrequency(String workState) async {
    // Si el estado es INACTIVO, detener tracking
    if (workState == 'INACTIVO') {
      print(
        '⏸️ updateTrackingFrequency: Deteniendo tracking por estado INACTIVO',
      );
      try {
        await BackgroundLocationService.stopTracking();
      } catch (e) {
        print('⚠️ Error deteniendo tracking (ignorado): $e');
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_state', workState);

    int intervalSeconds;
    switch (workState) {
      case 'EN_RUTA':
        intervalSeconds = 30; // 30 segundos
        break;
      case 'JORNADA_ACTIVA':
        intervalSeconds = 300; // 5 minutos
        break;
      default:
        intervalSeconds = 600;
    }
    await prefs.setInt('tracking_interval_seconds', intervalSeconds);

    await prefs.setInt('last_location_sent', 0);

    final service = FlutterBackgroundService();
    
    // Enviar comandos de forma segura
    try {
      service.invoke('updateFrequency', {
        'seconds': intervalSeconds,
        'workState': workState,  
      });
      print('✅ Frecuencia actualizada enviada al servicio');
    } catch (e) {
      print('⚠️ Error enviando updateFrequency: $e');
    }

    // Actualizar notificación
    try {
      service.invoke('updateNotification', {
        'workState': workState,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Notificación actualizada');
    } catch (e) {
      print('⚠️ Error actualizando notificación: $e');
    }

    print('🔄 Frecuencia actualizada: $workState cada ${intervalSeconds}s');
    
    // NUEVO: Enviar ubicación inmediatamente con el nuevo work_state
    // para garantizar que el backend reciba el cambio de estado
    try {
      print('📍 Enviando ubicación inmediata con nuevo work_state...');
      final position = await LocationService.getCurrentLocation();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('auth_token');
      
      // Obtener pedido_id si el estado es EN_RUTA
      int? pedidoId;
      if (workState == 'EN_RUTA') {
        pedidoId = prefs.getInt('current_pedido_id');
        print('   📦 Pedido activo ID (envío inmediato): $pedidoId');
      }
      
      if (userId != null && token != null) {
        await LocationRepository.sendLocation(
          userId: userId,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          workState: workState,
          speed: position.speed,
          heading: position.heading,
          token: token,
          pedidoId: pedidoId,  
        );
        print('✅ Ubicación enviada con nuevo work_state: $workState');
      }
    } catch (e) {
      print('⚠️ Error enviando ubicación inmediata: $e');
    }
  }
}
