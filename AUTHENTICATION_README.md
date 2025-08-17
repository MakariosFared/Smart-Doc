# 🔐 Authentication System - Complete Implementation

## 🎯 **Overview**

This document describes the complete authentication system implemented using **Cubit, State, Repository, and RepositoryImpl** with clean architecture (MVVM style) for the Smart Doc Flutter application.

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  AuthCubit (State Management)                              │
│  AuthState (State Classes)                                 │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                            │
├─────────────────────────────────────────────────────────────┤
│  AuthRepository (Abstract Interface)                       │
│  AuthException (Custom Exception)                          │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                              │
├─────────────────────────────────────────────────────────────┤
│  AuthRepositoryImpl (Concrete Implementation)              │
│  User (Data Model)                                         │
├─────────────────────────────────────────────────────────────┤
│                Dependency Injection                        │
├─────────────────────────────────────────────────────────────┤
│  AuthDependencyInjection                                  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 **File Structure**

```
lib/Features/auth/
├── data/
│   ├── models/
│   │   └── user.dart                    # User data model
│   └── repositories/
│       └── auth_repository_impl.dart    # Concrete repository implementation
├── domain/
│   └── repositories/
│       └── auth_repository.dart         # Abstract repository interface
├── presentation/
│   └── cubit/
│       ├── auth_cubit.dart              # Authentication business logic
│       └── auth_state.dart              # State management classes
├── di/
│   └── auth_dependency_injection.dart   # Dependency injection
├── example_usage.dart                   # Usage examples
└── index.dart                           # Export file
```

## 🔧 **Components Implementation**

### **1. User Model** (`lib/Features/auth/data/models/user.dart`)

```dart
class User {
  final String id;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.role,
  });

  // JSON serialization methods
  factory User.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();

  // Utility methods
  User copyWith({String? id, String? email, String? role});
}
```

**Features:**

- ✅ **Immutable**: All fields are final
- ✅ **JSON Support**: Easy serialization/deserialization
- ✅ **Copy Support**: Create modified copies easily
- ✅ **Equality**: Proper `==` and `hashCode` implementation

### **2. AuthRepository Interface** (`lib/Features/auth/domain/repositories/auth_repository.dart`)

```dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> signup(String email, String password, String role);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isAuthenticated();
}
```

**Features:**

- ✅ **Abstract**: Pure interface definition
- ✅ **Async Operations**: All methods return Futures
- ✅ **Error Handling**: Throws custom AuthException
- ✅ **Extensible**: Easy to add new methods

### **3. AuthRepositoryImpl** (`lib/Features/auth/data/repositories/auth_repository_impl.dart`)

**Mock Authentication Logic:**

- **Doctor Login**: `test@test.com` / `123456` → Returns doctor user
- **Patient Login**: `patient@test.com` / `123456` → Returns patient user
- **Admin Login**: `admin@test.com` / `123456` → Returns doctor user
- **Invalid Credentials**: Any other combination → Throws AuthException

**Features:**

- ✅ **Mock Implementation**: Ready for testing
- ✅ **Validation**: Email format, password length, role validation
- ✅ **Error Simulation**: Realistic error scenarios
- ✅ **Network Simulation**: Artificial delays for realistic UX
- ✅ **State Persistence**: Maintains current user in memory

### **4. AuthState Classes** (`lib/Features/auth/presentation/cubit/auth_state.dart`)

```dart
abstract class AuthState extends Equatable {
  // Base class for all authentication states
}

class AuthInitial extends AuthState {}           // App startup
class AuthLoading extends AuthState {}           // Authentication in progress
class AuthSuccess extends AuthState {}           // Authentication successful
class AuthFailure extends AuthState {}           // Authentication failed
class AuthUnauthenticated extends AuthState {}  // User not authenticated
class AuthLogoutLoading extends AuthState {}     // Logout in progress
class AuthLogoutSuccess extends AuthState {}     // Logout successful
```

**Features:**

- ✅ **Equatable**: Automatic state comparison
- ✅ **Type Safety**: Each state has specific data
- ✅ **Comprehensive**: Covers all authentication scenarios
- ✅ **Immutable**: States cannot be modified after creation

### **5. AuthCubit** (`lib/Features/auth/presentation/cubit/auth_cubit.dart`)

**Core Methods:**

- `login(String email, String password)` → Authenticates user
- `signup(String email, String password, String role)` → Registers new user
- `logout()` → Logs out current user
- `checkAuthStatus()` → Checks current authentication status

**Helper Methods:**

- `hasRole(String role)` → Check if user has specific role
- `isDoctor` / `isPatient` → Role-specific boolean getters
- `currentUserEmail` / `currentUserRole` → User information getters
- `isAuthenticated` / `isLoading` / `isLoggingOut` → State boolean getters
- `errorMessage` / `errorCode` → Error information getters

**Features:**

- ✅ **State Management**: Emits appropriate states for each operation
- ✅ **Error Handling**: Catches and handles all exceptions
- ✅ **Role Management**: Easy role checking and validation
- ✅ **State Queries**: Convenient getters for common state checks
- ✅ **Error Recovery**: Methods to clear error states

## 🚀 **Usage Examples**

### **Basic Setup in Main App**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Features/auth/index.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(
        authRepository: AuthDependencyInjection.authRepository,
      ),
      child: MaterialApp(
        // ... your app configuration
      ),
    );
  }
}
```

### **Using AuthCubit in Widgets**

```dart
class LoginWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // Navigate based on role
          if (state.user.role == 'doctor') {
            Navigator.pushReplacementNamed(context, '/doctor-home');
          } else {
            Navigator.pushReplacementNamed(context, '/patient-home');
          }
        } else if (state is AuthFailure) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return CircularProgressIndicator();
        }

        return ElevatedButton(
          onPressed: () {
            context.read<AuthCubit>().login('email@test.com', 'password');
          },
          child: Text('Login'),
        );
      },
    );
  }
}
```

### **State Checking in Widgets**

```dart
class ProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();

        if (cubit.isAuthenticated) {
          return Column(
            children: [
              Text('Welcome ${cubit.currentUserEmail}'),
              if (cubit.isDoctor) Text('Doctor Dashboard'),
              if (cubit.isPatient) Text('Patient Dashboard'),
              ElevatedButton(
                onPressed: () => cubit.logout(),
                child: Text('Logout'),
              ),
            ],
          );
        }

        return Text('Please login');
      },
    );
  }
}
```

## 🧪 **Testing the Authentication System**

### **Test Credentials**

| Email              | Password | Role    | Expected Result   |
| ------------------ | -------- | ------- | ----------------- |
| `test@test.com`    | `123456` | Doctor  | ✅ Success        |
| `patient@test.com` | `123456` | Patient | ✅ Success        |
| `admin@test.com`   | `123456` | Doctor  | ✅ Success        |
| `invalid@test.com` | `wrong`  | -       | ❌ Failure        |
| `newuser@test.com` | `123456` | Patient | ✅ Signup Success |

### **Running the Example**

1. **Add to your app**: Import the `AuthExample` widget
2. **Test login**: Use the provided test credentials
3. **Test signup**: Try creating new accounts
4. **Test errors**: Use invalid credentials to see error handling

## 🔄 **Migration to Firebase**

### **Current Mock Implementation**

- ✅ **Ready for replacement**: Clean interface separation
- ✅ **Same API**: No changes needed in Cubit or UI
- ✅ **Error handling**: Custom exceptions already implemented
- ✅ **State management**: All states remain the same

### **Firebase Integration Steps**

1. **Replace RepositoryImpl**: Create `FirebaseAuthRepositoryImpl`
2. **Update Dependencies**: Add Firebase packages to `pubspec.yaml`
3. **Configure Firebase**: Set up Firebase project and configuration
4. **Test Integration**: Verify all authentication flows work

### **Example Firebase Implementation**

```dart
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role from Firestore
      final role = await _getUserRole(credential.user!.uid);

      return User(
        id: credential.user!.uid,
        email: email,
        role: role,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  // ... implement other methods
}
```

## 📋 **Dependencies Required**

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
```

## 🎯 **Key Benefits**

### **Architecture Benefits**

- ✅ **Clean Separation**: Clear separation of concerns
- ✅ **Testable**: Easy to unit test each component
- ✅ **Maintainable**: Well-structured, easy to modify
- ✅ **Scalable**: Easy to add new features

### **Development Benefits**

- ✅ **Type Safety**: Strong typing throughout
- ✅ **Error Handling**: Comprehensive error management
- ✅ **State Management**: Predictable state changes
- ✅ **Role Management**: Built-in role validation

### **Production Benefits**

- ✅ **Performance**: Efficient state management
- ✅ **Reliability**: Robust error handling
- ✅ **User Experience**: Smooth authentication flows
- ✅ **Security**: Proper authentication validation

## 🚀 **Next Steps**

1. **Test the System**: Use the provided example to verify functionality
2. **Integrate with UI**: Connect existing login/signup forms to AuthCubit
3. **Add Persistence**: Implement local storage for user sessions
4. **Firebase Integration**: Replace mock implementation with real Firebase auth
5. **Advanced Features**: Add password reset, email verification, etc.

---

**Status**: ✅ **Complete Implementation**
**Ready for**: UI integration and Firebase migration
**Testing**: Comprehensive example provided
**Documentation**: Full coverage with examples
