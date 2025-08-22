import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_repository.dart';
import '../models/app_user.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Temporary in-memory storage for when Firestore is not available
  final Map<String, AppUser> _tempUserStorage = {};

  // Collection reference for user profiles
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user == null) {
        throw const AuthException('فشل في تسجيل الدخول');
      }

      // Fetch user profile from Firestore
      try {
        final AppUser appUser = await _getUserProfile(
          user.uid,
        ).timeout(const Duration(seconds: 10));
        return appUser;
      } on TimeoutException {
        // Check temporary storage as fallback
        if (_tempUserStorage.containsKey(user.uid)) {
          print('Firestore timeout - returning user from temporary storage');
          return _tempUserStorage[user.uid]!;
        }
        throw const AuthException(
          'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
          code: 'FIRESTORE_TIMEOUT',
        );
      } on FirebaseException catch (firestoreError) {
        // Handle Firestore-specific errors
        if (firestoreError.code == 'not-found') {
          // Check temporary storage as fallback
          if (_tempUserStorage.containsKey(user.uid)) {
            print(
              'Firestore not found - returning user from temporary storage',
            );
            return _tempUserStorage[user.uid]!;
          }
          throw const AuthException(
            'قاعدة البيانات غير موجودة. يرجى التأكد من إعداد Firestore في مشروع Firebase.',
            code: 'FIRESTORE_NOT_FOUND',
          );
        } else if (firestoreError.code == 'permission-denied') {
          throw const AuthException(
            'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
            code: 'FIRESTORE_PERMISSION_DENIED',
          );
        } else {
          // Check temporary storage as fallback
          if (_tempUserStorage.containsKey(user.uid)) {
            print(
              'Firestore error - returning user from temporary storage: ${firestoreError.message}',
            );
            return _tempUserStorage[user.uid]!;
          }
          throw AuthException(
            'خطأ في قاعدة البيانات: ${firestoreError.message}',
            code: firestoreError.code,
          );
        }
      } catch (e) {
        // Check temporary storage as fallback
        if (_tempUserStorage.containsKey(user.uid)) {
          print('Unknown error - returning user from temporary storage');
          return _tempUserStorage[user.uid]!;
        }
        // Handle other Firestore errors
        throw const AuthException(
          'فشل في جلب بيانات المستخدم من قاعدة البيانات. يرجى المحاولة مرة أخرى.',
          code: 'FIRESTORE_ERROR',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('حدث خطأ غير متوقع أثناء تسجيل الدخول');
    }
  }

  @override
  Future<AppUser> signup(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      print('Starting signup process for: $email');

      // Create user with Firebase Auth
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user == null) {
        print('Firebase Auth user creation failed');
        throw const AuthException('فشل في إنشاء الحساب');
      }

      print('Firebase Auth user created successfully: ${user.uid}');

      // Create user profile in Firestore
      final AppUser appUser = AppUser(
        id: user.uid,
        name: name,
        emailOrPhone: email,
        role: role,
      );

      print('Attempting to save user profile to Firestore...');

      try {
        // Add timeout to prevent hanging
        await _usersCollection
            .doc(user.uid)
            .set(appUser.toJson())
            .timeout(const Duration(seconds: 10));
        print('User profile saved to Firestore successfully');
      } on TimeoutException {
        // Store temporarily in memory as fallback
        _tempUserStorage[user.uid] = appUser;
        print('Firestore timeout - storing user temporarily in memory');
      } on FirebaseException catch (firestoreError) {
        // Handle Firestore-specific errors
        if (firestoreError.code == 'not-found') {
          // Store temporarily in memory as fallback
          _tempUserStorage[user.uid] = appUser;
          print('Firestore not found - storing user temporarily in memory');
        } else if (firestoreError.code == 'permission-denied') {
          print('Firestore permission denied: ${firestoreError.message}');
          throw const AuthException(
            'لا توجد صلاحيات للكتابة في قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
            code: 'FIRESTORE_PERMISSION_DENIED',
          );
        } else {
          // Store temporarily in memory as fallback for other Firestore errors
          _tempUserStorage[user.uid] = appUser;
          print(
            'Firestore error - storing user temporarily in memory: ${firestoreError.message}',
          );
        }
      } catch (e) {
        // Store temporarily in memory as fallback
        _tempUserStorage[user.uid] = appUser;
        print('Unknown error - storing user temporarily in memory: $e');
      }

      print(
        'Signup completed successfully. User stored in: ${_tempUserStorage.containsKey(user.uid) ? 'temporary memory' : 'Firestore'}',
      );
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      throw AuthException(_getErrorMessage(e.code), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      print('Unexpected error during signup: $e');
      throw const AuthException('حدث خطأ غير متوقع أثناء إنشاء الحساب');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const AuthException('حدث خطأ أثناء تسجيل الخروج');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) return null;

      return await _getUserProfile(user.uid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to fetch user profile from Firestore
  Future<AppUser> _getUserProfile(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        throw const AuthException('لم يتم العثور على ملف المستخدم');
      }

      final data = doc.data()!;
      return AppUser.fromJson(data);
    } on TimeoutException {
      // Check temporary storage as fallback
      if (_tempUserStorage.containsKey(uid)) {
        print('Firestore timeout - returning user from temporary storage');
        return _tempUserStorage[uid]!;
      }
      throw const AuthException(
        'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        code: 'FIRESTORE_TIMEOUT',
      );
    } on FirebaseException catch (firestoreError) {
      // Handle Firestore-specific errors
      if (firestoreError.code == 'not-found') {
        // Check temporary storage as fallback
        if (_tempUserStorage.containsKey(uid)) {
          print('Firestore not found - returning user from temporary storage');
          return _tempUserStorage[uid]!;
        }
        throw const AuthException(
          'قاعدة البيانات غير موجودة. يرجى التأكد من إعداد Firestore في مشروع Firebase.',
          code: 'FIRESTORE_NOT_FOUND',
        );
      } else if (firestoreError.code == 'permission-denied') {
        throw const AuthException(
          'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
          code: 'FIRESTORE_PERMISSION_DENIED',
        );
      } else {
        // Check temporary storage as fallback
        if (_tempUserStorage.containsKey(uid)) {
          print(
            'Firestore error - returning user from temporary storage: ${firestoreError.message}',
          );
          return _tempUserStorage[uid]!;
        }
        throw AuthException(
          'خطأ في قاعدة البيانات: ${firestoreError.message}',
          code: firestoreError.code,
        );
      }
    } catch (e) {
      // Check temporary storage as fallback
      if (_tempUserStorage.containsKey(uid)) {
        print('Unknown error - returning user from temporary storage');
        return _tempUserStorage[uid]!;
      }
      if (e is AuthException) rethrow;
      throw const AuthException('فشل في جلب بيانات المستخدم');
    }
  }

  /// Helper method to convert Firebase Auth error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لم يتم العثور على المستخدم';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز الحد الأقصى للمحاولات، يرجى المحاولة لاحقاً';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'network-request-failed':
        return 'فشل في الاتصال بالشبكة';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }

  /// Helper method to update user profile in Firestore
  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      throw const AuthException('فشل في تحديث بيانات المستخدم');
    }
  }

  /// Helper method to delete user account
  Future<void> deleteUserAccount() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        // Delete from Firestore first
        await _usersCollection.doc(user.uid).delete();
        // Then delete from Firebase Auth
        await user.delete();
        // Clear from temporary storage
        _tempUserStorage.remove(user.uid);
      }
    } catch (e) {
      throw const AuthException('فشل في حذف الحساب');
    }
  }

  /// Helper method to migrate temporary users to Firestore
  Future<void> migrateTempUsersToFirestore() async {
    try {
      for (final entry in _tempUserStorage.entries) {
        try {
          await _usersCollection.doc(entry.key).set(entry.value.toJson());
          print('Migrated user ${entry.value.emailOrPhone} to Firestore');
        } catch (e) {
          print('Failed to migrate user ${entry.value.emailOrPhone}: $e');
        }
      }
      // Clear temporary storage after successful migration
      _tempUserStorage.clear();
    } catch (e) {
      print('Failed to migrate temporary users: $e');
    }
  }

  /// Helper method to check if Firestore is available
  Future<bool> isFirestoreAvailable() async {
    try {
      await _firestore
          .collection('_health_check')
          .doc('test')
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<AppUser>> getAllDoctors() async {
    try {
      print('🔄 Fetching fresh doctors data from Firebase...');

      // Force fresh data from server, not from cache
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      final doctors = <AppUser>[];

      for (final doc in querySnapshot.docs) {
        try {
          final userData = doc.data();
          // Add the document ID to the data
          userData['id'] = doc.id;
          final doctor = AppUser.fromJson(userData);
          doctors.add(doctor);
          print('✅ Added doctor: ${doctor.name} (ID: ${doctor.id})');
        } catch (e) {
          print('❌ Error parsing doctor data for document ${doc.id}: $e');
          // Continue with other documents
        }
      }

      print(
        '✅ Successfully fetched ${doctors.length} fresh doctors from Firebase server',
      );
      return doctors;
    } on TimeoutException {
      throw const AuthException(
        'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        code: 'FIRESTORE_TIMEOUT',
      );
    } on FirebaseException catch (firestoreError) {
      if (firestoreError.code == 'permission-denied') {
        throw const AuthException(
          'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
          code: 'FIRESTORE_PERMISSION_DENIED',
        );
      } else {
        throw AuthException(
          'خطأ في قاعدة البيانات: ${firestoreError.message}',
          code: firestoreError.code,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('فشل في جلب قائمة الأطباء');
    }
  }

  /// Clear all temporary user storage
  void clearAllTempUsers() {
    _tempUserStorage.clear();
    print('🧹 Cleared all temporary user storage');
  }

  /// Clear temporary storage for a specific user
  void clearTempUser(String userId) {
    _tempUserStorage.remove(userId);
    print('🧹 Cleared temporary storage for user: $userId');
  }

  /// Force refresh doctors data by clearing cache and fetching from server
  Future<List<AppUser>> refreshDoctorsData() async {
    try {
      print('🔄 Force refreshing doctors data...');

      // Clear any temporary storage
      clearAllTempUsers();

      // Fetch fresh data from server
      return await getAllDoctors();
    } catch (e) {
      print('❌ Error refreshing doctors data: $e');
      rethrow;
    }
  }
}
