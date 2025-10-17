import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/models/user.dart';
import '../../../../core/services/user_service.dart';
import '../../../features/auth/application/auth_notifier.dart';

final motorizadoUsersProvider = FutureProvider<List<User>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.token;

  if (token == null || token.isEmpty) {
    throw Exception('No hay token de autenticación para obtener los usuarios.');
  }

  return await UserService().fetchUsers(token: token, role: 'MOTORIZADO');
});

final deleteUserProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  final authState = ref.read(authNotifierProvider);
  final token = authState.token;
  if (token == null || token.isEmpty) {
    throw Exception('No hay token de autenticación para eliminar usuario.');
  }
  final response = await UserService().deleteUser(userId: userId, token: token);
  if (response.statusCode != 200) {
    throw Exception('Error al eliminar usuario: ${response.body}');
  }
  // Opcional: refresca la lista de usuarios
  ref.invalidate(motorizadoUsersProvider);
});
