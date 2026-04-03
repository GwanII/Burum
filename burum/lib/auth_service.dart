import 'dart:async';

enum AuthStatus { unauthenticated }

class AuthService {
  // Private constructor
  AuthService._();

  // Singleton instance
  static final AuthService instance = AuthService._();

  final StreamController<AuthStatus> _authStatusController =
      StreamController<AuthStatus>.broadcast();

  Stream<AuthStatus> get authStatusStream => _authStatusController.stream;

  void notifyAuthStatus(AuthStatus status) {
    _authStatusController.add(status);
  }

  void dispose() {
    _authStatusController.close();
  }
}
