import '../../data/models/user.dart';

abstract class AuthRepository {
  /// Authenticates a user with email and password
  ///
  /// Returns a [User] object if authentication is successful
  /// Throws an [AuthException] if authentication fails
  Future<User> login(String email, String password);

  /// Registers a new user with email, password, and role
  ///
  /// Returns a [User] object if registration is successful
  /// Throws an [AuthException] if registration fails
  Future<User> signup(String email, String password, String role);

  /// Logs out the current user
  ///
  /// Clears any stored authentication data
  Future<void> logout();

  /// Gets the current authenticated user
  ///
  /// Returns the current [User] if authenticated, null otherwise
  Future<User?> getCurrentUser();

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
