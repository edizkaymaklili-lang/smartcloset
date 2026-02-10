enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final String? userId;
  final String? email;
  final String? displayName;
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.userId,
    this.email,
    this.displayName,
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    String? userId,
    String? email,
    String? displayName,
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
