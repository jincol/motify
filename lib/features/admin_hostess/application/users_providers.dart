import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/models/user.dart';
// import 'package:motify/core/services/user_service.dart';
// import '../../../features/auth/application/auth_notifier.dart';

// Este provider obtiene la lista de usuarios con rol ANFITRIONA
// que pertenecen al grupo del admin anfitriona autenticado.
// final anfitrionaUsersProvider = FutureProvider<List<User>>((ref) async {
//   final authState = ref.watch(authNotifierProvider);
//   final token = authState.token;

//   if (token == null || token.isEmpty) {
//     throw Exception('No hay token de autenticación para obtener los usuarios.');
//   }

//   return await UserService().fetchUsers(token: token, role: 'ANFITRIONA');
// });

final anfitrionaUsersProvider = FutureProvider<List<User>>((ref) async {
  return [
    User(
      id: 1,
      username: 'ana.gomez',
      role: 'ANFITRIONA',
      workState: 'JORNADA_ACTIVA',
      grupoId: 1,
      avatarUrl: null,
      fullName: 'Ana Gómez',
      isActive: true,
      isSuperuser: false,
    ),
    User(
      id: 1,
      username: 'ana.gomez',
      role: 'ANFITRIONA',
      workState: 'JORNADA_ACTIVA',
      grupoId: 1,
      avatarUrl: null,
      fullName: 'Ano Gómoz',
      isActive: true,
      isSuperuser: false,
    ),
    User(
      id: 1,
      username: 'ana.gomez',
      role: 'ANFITRIONA',
      workState: 'JORNADA_ACTIVA',
      grupoId: 1,
      avatarUrl: null,
      fullName: 'Ana Gómez',
      isActive: true,
      isSuperuser: false,
    ),
    User(
      id: 1,
      username: 'ana.gomez',
      role: 'ANFITRIONA',
      workState: 'INACTIVO',
      grupoId: 1,
      avatarUrl: null,
      fullName: 'Ana Gómez',
      isActive: true,
      isSuperuser: false,
    ),

    // Agrega más usuarios ficticios si lo deseas
  ];
});
