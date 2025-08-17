import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/app_user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial());

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      emit(const AuthLoading());

      final user = await _authRepository.login(email, password);
      emit(AuthSuccess(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message, code: e.code));
    } catch (e) {
      emit(AuthFailure('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'));
    }
  }

  /// Signup with name, email, password, and role
  Future<void> signup(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await _authRepository.signup(name, email, password, role);
      emit(AuthSuccess(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message, code: e.code));
    } catch (e) {
      emit(AuthFailure('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'));
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      emit(const AuthLogoutLoading());

      await _authRepository.logout();
      emit(const AuthLogoutSuccess());
    } catch (e) {
      emit(AuthFailure('حدث خطأ أثناء تسجيل الخروج. يرجى المحاولة مرة أخرى.'));
    }
  }

  /// Check if user is authenticated
  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthSuccess(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Get current user without changing state
  Future<AppUser?> getCurrentUser() async {
    try {
      return await _authRepository.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  /// Check if current user has a specific role
  bool hasRole(UserRole role) {
    if (state is AuthSuccess) {
      final authState = state as AuthSuccess;
      return authState.user.role == role;
    }
    return false;
  }

  /// Check if current user is a doctor
  bool get isDoctor => hasRole(UserRole.doctor);

  /// Check if current user is a patient
  bool get isPatient => hasRole(UserRole.patient);

  /// Get current user email
  String? get currentUserEmail {
    if (state is AuthSuccess) {
      final authState = state as AuthSuccess;
      return authState.user.emailOrPhone;
    }
    return null;
  }

  /// Get current user name
  String? get currentUserName {
    if (state is AuthSuccess) {
      final authState = state as AuthSuccess;
      return authState.user.name;
    }
    return null;
  }

  /// Get current user role
  UserRole? get currentUserRole {
    if (state is AuthSuccess) {
      final authState = state as AuthSuccess;
      return authState.user.role;
    }
    return null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state is AuthSuccess;

  /// Check if authentication is in progress
  bool get isLoading => state is AuthLoading;

  /// Check if logout is in progress
  bool get isLoggingOut => state is AuthLogoutLoading;

  /// Get error message if authentication failed
  String? get errorMessage {
    if (state is AuthFailure) {
      final authState = state as AuthFailure;
      return authState.message;
    }
    return null;
  }

  /// Get error code if authentication failed
  String? get errorCode {
    if (state is AuthFailure) {
      final authState = state as AuthFailure;
      return authState.code;
    }
    return null;
  }

  /// Clear error state
  void clearError() {
    if (state is AuthFailure) {
      checkAuthStatus();
    }
  }

  /// Check if Firestore is available and migrate temporary users
  Future<void> checkFirestoreAndMigrate() async {
    try {
      // This is a temporary solution - in a real app, you'd inject the repository
      // and call the method directly
      print('Checking Firestore availability...');
      // For now, just emit a message - you can implement the actual check later
    } catch (e) {
      print('Error checking Firestore: $e');
    }
  }
}
