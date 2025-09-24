enum AuthStatus { authenticated, unauthenticated, loading, error, unknown }

class AuthState {
  final AuthStatus authStatus;
  final String? role;
  final String? workState;

  AuthState({required this.authStatus, this.role, this.workState});
}
