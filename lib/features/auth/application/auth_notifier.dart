import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_state.dart';
import 'dart:convert';
import 'package:motify/core/services/auth_repository.dart';
import 'dart:developer' as developer;
import 'package:motify/core/constants/api_config.dart';
import 'package:motify/core/services/background_location_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  static final String _baseUrl = '${ApiConfig.baseApiUrl}/auth/token';
  final _storage = const FlutterSecureStorage();
  
  AuthNotifier() : super(AuthState(authStatus: AuthStatus.unknown)) {
    _initializeAuth();
  }

  /// Inicializar autenticación al arrancar la app
  Future<void> _initializeAuth() async {
    try {
      developer.log('🔐 Inicializando autenticación...', name: 'auth_notifier');
      
      // Verificar si hay un token guardado
      final token = await _storage.read(key: 'token');
      
      if (token == null || token.isEmpty) {
        developer.log('❌ No hay token guardado', name: 'auth_notifier');
        state = AuthState(authStatus: AuthStatus.unauthenticated);
        return;
      }

      developer.log('✅ Token encontrado, verificando sesión...', name: 'auth_notifier');
      
      // Verificar si el token es válido llamando a /users/me
      final meResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (meResponse.statusCode == 200) {
        final meData = jsonDecode(meResponse.body);
        final userId = meData['id'];
        final role = meData['role'];
        final workState = meData['work_state'] ?? 'INACTIVO';
        
        developer.log(
          '✅ Sesión restaurada: userId=$userId, role=$role, workState=$workState',
          name: 'auth_notifier',
        );
        
        // Guardar en SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          await prefs.setString('work_state', workState);
          await prefs.setString('auth_token', token);
        } catch (e) {
          developer.log('⚠️ Error guardando en prefs: $e', name: 'auth_notifier');
        }
        
        // Restaurar estado de autenticación
        state = AuthState(
          authStatus: AuthStatus.authenticated,
          role: role,
          workState: workState,
          token: token,
          userId: userId,
        );

        // 🚀 IMPORTANTE: Reiniciar tracking GPS si la jornada está activa
        if (workState == 'JORNADA_ACTIVA' || workState == 'EN_RUTA') {
          developer.log(
            '🚀 Reiniciando tracking GPS con estado: $workState',
            name: 'auth_notifier',
          );
          
          try {
            await BackgroundLocationService.startTracking(
              userId: userId,
              workState: workState,
              token: token,
            );
            developer.log('✅ Tracking GPS reiniciado exitosamente', name: 'auth_notifier');
          } catch (e) {
            developer.log('⚠️ Error reiniciando tracking GPS: $e', name: 'auth_notifier');
          }
        }
      } else {
        // Token inválido o expirado
        developer.log(
          '❌ Token inválido (${meResponse.statusCode})',
          name: 'auth_notifier',
        );
        await _storage.delete(key: 'token');
        state = AuthState(authStatus: AuthStatus.unauthenticated);
      }
    } catch (e) {
      developer.log('❌ Error en _initializeAuth: $e', name: 'auth_notifier');
      state = AuthState(authStatus: AuthStatus.unauthenticated);
    }
  }
  Future<void> login(String username, String password) async {
    state = AuthState(authStatus: AuthStatus.loading);
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=password&username=$username&password=$password',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refresh = data['refresh_token'];
        try {
          await AuthRepository.saveTokens(
            accessToken: token,
            refreshToken: refresh ?? '',
            alsoSaveToPrefs: true,
          );
        } catch (_) {
          await _storage.write(key: 'token', value: token);
          if (refresh != null) {
            await _storage.write(key: 'refresh_token', value: refresh);
          }
        }

        final meResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body);
          final role = meData['role'];
          final workState = meData['work_state'];
          final userId = meData['id'];
          
          // Guardar user_id en SharedPreferences para uso del mapa y otros servicios
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', userId);
            await prefs.setString('work_state', workState);
          } catch (e) {
            developer.log('Error guardando user_id en prefs: $e', name: 'auth_notifier');
          }
          
          state = AuthState(
            authStatus: AuthStatus.authenticated,
            role: role,
            workState: workState,
            token: token,
            userId: userId,
          );
        } else {
          state = AuthState(authStatus: AuthStatus.error);
        }
      } else {
        state = AuthState(authStatus: AuthStatus.error);
      }
    } catch (e) {
      state = AuthState(authStatus: AuthStatus.error);
    }
  }

  Future<void> logout() async {
    // Borrar token seguro
    await _storage.delete(key: 'token');

    // Limpiar SharedPreferences que pueda usar el background service
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('auth_token');
      await prefs.remove('work_state');
      await prefs.remove('tracking_interval_seconds');
      await prefs.remove('last_location_sent');
    } catch (e) {
      // no bloquear logout si falla limpiar prefs
      developer.log(
        'Error limpiando SharedPreferences en logout: $e',
        name: 'auth_notifier',
      );
    }

    state = AuthState(authStatus: AuthStatus.unauthenticated);
  }

  Future<void> fetchMe() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    final meResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (meResponse.statusCode == 200) {
      final meData = jsonDecode(meResponse.body);
      final userId = meData['id'];
      final role = meData['role'];
      final workState = meData['work_state'];
      
      // Guardar user_id en SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setString('work_state', workState);
      } catch (e) {
        developer.log('Error guardando user_id en prefs: $e', name: 'auth_notifier');
      }
      
      state = AuthState(
        authStatus: AuthStatus.authenticated,
        role: role,
        workState: workState,
        token: token,
        userId: userId,
      );
    }
  }

  //change new
  void resetState() {
    state = AuthState(authStatus: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier();
});
