abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final dynamic user;
  const Authenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthOtpSent extends AuthState {
  final String email;
  const AuthOtpSent(this.email);
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}
