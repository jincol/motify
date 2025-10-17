import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/models/user.dart';
import '../../../core/services/user_service.dart';
import '../../features/auth/application/auth_notifier.dart';

class adminUsersProvider extends StateNotifier<AsyncValue<List<User>>> {
  adminUsersProvider(this.ref, {required this.role})
    : super(const AsyncValue.loading()) {
    _loadUsers();
  }

  final Ref ref;
  final String role;

  Future<void> _loadUsers() async {
    state = const AsyncValue.loading();
    final authState = ref.read(authNotifierProvider);
    final token = authState.token;
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final users = await UserService().fetchUsers(token: token, role: role);
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateUserState(int userId, String newState) {
    state.whenData((users) {
      state = AsyncValue.data([
        for (final user in users)
          if (user.id == userId) user.copyWith(workState: newState) else user,
      ]);
    });
  }

  Future<void> refresh() async => _loadUsers();

  Future<void> deleteUser(int userId) async {
    final authState = ref.read(authNotifierProvider);
    final token = authState.token;
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación para eliminar usuario.');
    }
    final response = await UserService().deleteUser(
      userId: userId.toString(),
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario: ${response.body}');
    }
    await _loadUsers();
  }
}

final adminHostessUsersProvider =
    StateNotifierProvider<adminUsersProvider, AsyncValue<List<User>>>(
      (ref) => adminUsersProvider(ref, role: 'ANFITRIONA'),
    );

final adminMotorizedUsersProvider =
    StateNotifierProvider<adminUsersProvider, AsyncValue<List<User>>>(
      (ref) => adminUsersProvider(ref, role: 'MOTORIZADO'),
    );
