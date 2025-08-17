import '../data/repositories/firebase_auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

/// Dependency injection for authentication
class AuthDependencyInjection {
  static AuthRepository? _authRepository;

  /// Get the AuthRepository instance
  static AuthRepository get authRepository {
    _authRepository ??= FirebaseAuthRepositoryImpl();
    return _authRepository!;
  }

  /// Reset the AuthRepository instance (useful for testing)
  static void reset() {
    _authRepository = null;
  }
}
