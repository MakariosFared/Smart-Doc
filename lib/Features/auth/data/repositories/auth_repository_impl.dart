import '../../domain/repositories/auth_repository.dart';
import '../models/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Mock storage for current user
  User? _currentUser;

  @override
  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication logic
    if (email == "test@test.com" && password == "123456") {
      // Return doctor user
      _currentUser = const User(
        id: "doctor_001",
        email: "test@test.com",
        role: "doctor",
      );
      return _currentUser!;
    } else if (email == "patient@test.com" && password == "123456") {
      // Return patient user
      _currentUser = const User(
        id: "patient_001",
        email: "patient@test.com",
        role: "patient",
      );
      return _currentUser!;
    } else if (email == "admin@test.com" && password == "123456") {
      // Return admin user (can be either role)
      _currentUser = const User(
        id: "admin_001",
        email: "admin@test.com",
        role: "doctor", // Default to doctor role
      );
      return _currentUser!;
    } else {
      // Invalid credentials
      throw const AuthException(
        "البريد الإلكتروني أو كلمة المرور غير صحيحة",
        code: "INVALID_CREDENTIALS",
      );
    }
  }

  @override
  Future<User> signup(String email, String password, String role) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate email format
    if (!_isValidEmail(email)) {
      throw const AuthException(
        "البريد الإلكتروني غير صحيح",
        code: "INVALID_EMAIL",
      );
    }

    // Validate password length
    if (password.length < 6) {
      throw const AuthException(
        "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
        code: "WEAK_PASSWORD",
      );
    }

    // Validate role
    if (role != "doctor" && role != "patient") {
      throw const AuthException("نوع الحساب غير صحيح", code: "INVALID_ROLE");
    }

    // Check if email already exists (mock check)
    if (email == "test@test.com" ||
        email == "patient@test.com" ||
        email == "admin@test.com") {
      throw const AuthException(
        "البريد الإلكتروني مستخدم بالفعل",
        code: "EMAIL_ALREADY_EXISTS",
      );
    }

    // Generate mock user ID
    final userId = "${role}_${DateTime.now().millisecondsSinceEpoch}";

    // Create new user
    _currentUser = User(id: userId, email: email, role: role);

    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Clear current user
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    return _currentUser;
  }

  @override
  Future<bool> isAuthenticated() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    return _currentUser != null;
  }

  /// Helper method to validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Helper method to get mock users for testing
  List<User> getMockUsers() {
    return [
      const User(id: "doctor_001", email: "test@test.com", role: "doctor"),
      const User(id: "patient_001", email: "patient@test.com", role: "patient"),
      const User(id: "admin_001", email: "admin@test.com", role: "doctor"),
    ];
  }
}
