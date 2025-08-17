import 'package:equatable/equatable.dart';
import '../../data/models/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when authentication is successful
class AuthSuccess extends AuthState {
  final AppUser user;

  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];

  @override
  String toString() => 'AuthSuccess(user: $user)';
}

/// State when authentication fails
class AuthFailure extends AuthState {
  final String message;
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AuthFailure(message: $message, code: $code)';
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when logout is in progress
class AuthLogoutLoading extends AuthState {
  const AuthLogoutLoading();
}

/// State when logout is successful
class AuthLogoutSuccess extends AuthState {
  const AuthLogoutSuccess();
}
