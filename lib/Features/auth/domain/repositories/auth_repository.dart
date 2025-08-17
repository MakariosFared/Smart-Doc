import '../../data/models/app_user.dart';

abstract class AuthRepository {
  /// Authenticates a user with email and password
  ///
  /// Returns an [AppUser] object if authentication is successful
  /// Throws an [AuthException] if authentication fails
  Future<AppUser> login(String email, String password);

  /// Registers a new user with name, email, password, and role
  ///
  /// Returns an [AppUser] object if registration is successful
  /// Throws an [AuthException] if registration fails
  Future<AppUser> signup(
    String name,
    String email,
    String password,
    UserRole role,
  );

  /// Logs out the current user
  ///
  /// Clears any stored authentication data
  Future<void> logout();

  /// Gets the current authenticated user
  ///
  /// Returns the current [AppUser] if authenticated, null otherwise
  Future<AppUser?> getCurrentUser();

  /// Checks if a user is currently authenticated
  ///
  /// Returns true if authenticated, false otherwise
  Future<bool> isAuthenticated();
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}
