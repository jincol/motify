import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user.dart';
import '../../../../core/services/user_service.dart';
import '../../../features/auth/application/auth_notifier.dart';

// Este provider obtiene la lista de usuarios con rol MOTORIZADO
// que pertenecen al grupo del admin autenticado.
final motorizadoUsersProvider = FutureProvider<List<User>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.token;

  if (token == null || token.isEmpty) {
    throw Exception('No hay token de autenticación para obtener los usuarios.');
  }

  return await UserService().fetchUsers(token: token, role: 'MOTORIZADO');
});
