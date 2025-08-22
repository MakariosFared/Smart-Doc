import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/Features/auth/data/models/app_user.dart';
import '../repositories/booking_repository.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';

class FirebaseBookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Doctor>> getAvailableDoctors() async {
    try {
      print('🔍 Fetching doctors from Firebase...');

      // Query Firestore for all users with doctor role
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get()
          .timeout(const Duration(seconds: 10));

      print(
        '📊 Found ${querySnapshot.docs.length} doctor documents in Firestore',
      );

      final doctors = <Doctor>[];

      for (final doc in querySnapshot.docs) {
        try {
          final userData = doc.data();
          print('📋 Processing doctor document: ${doc.id}');
          print('📋 Document data: $userData');

          // Add the document ID to the data
          userData['id'] = doc.id;

          // Convert AppUser to Doctor model
          final doctor = _convertAppUserToDoctor(userData);
          doctors.add(doctor);
          print('✅ Successfully converted doctor: ${doctor.name}');
        } catch (e) {
          print('❌ Error parsing doctor data for document ${doc.id}: $e');
          // Continue with other documents
        }
      }

      print('✅ Successfully fetched ${doctors.length} doctors from Firebase');
      return doctors;
    } on TimeoutException {
      print('⏰ Timeout while fetching doctors from Firebase');
      throw const BookingException(
        'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        code: 'FIRESTORE_TIMEOUT',
      );
    } on FirebaseException catch (firestoreError) {
      print(
        '🔥 Firebase error while fetching doctors: ${firestoreError.code} - ${firestoreError.message}',
      );
      if (firestoreError.code == 'permission-denied') {
        throw const BookingException(
          'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
          code: 'FIRESTORE_PERMISSION_DENIED',
        );
      } else {
        throw BookingException(
          'خطأ في قاعدة البيانات: ${firestoreError.message}',
          code: firestoreError.code,
        );
      }
    } catch (e) {
      print('❌ Unexpected error while fetching doctors: $e');
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في جلب قائمة الأطباء');
    }
  }

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(doctorId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        return null;
      }

      final userData = doc.data()!;
      userData['id'] = doc.id;

      return _convertAppUserToDoctor(userData);
    } on TimeoutException {
      throw const BookingException(
        'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        code: 'FIRESTORE_TIMEOUT',
      );
    } on FirebaseException catch (firestoreError) {
      if (firestoreError.code == 'permission-denied') {
        throw const BookingException(
          'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
          code: 'FIRESTORE_PERMISSION_DENIED',
        );
      } else {
        throw BookingException(
          'خطأ في قاعدة البيانات: ${firestoreError.message}',
          code: firestoreError.code,
        );
      }
    } catch (e) {
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في جلب بيانات الدكتور');
    }
  }

  @override
  Future<List<String>> getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // For now, return default time slots
      // In a real implementation, you would query the doctor's schedule
      // and filter out already booked slots
      return ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];
    } catch (e) {
      throw const BookingException('فشل في جلب المواعيد المتاحة');
    }
  }

  @override
  Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String timeSlot,
    required DateTime appointmentDate,
    required Map<String, dynamic> questionnaireAnswers,
  }) async {
    try {
      // Create appointment document in Firestore
      final appointmentRef = _firestore.collection('appointments').doc();

      final appointment = Appointment(
        id: appointmentRef.id,
        patientId: patientId,
        doctorId: doctorId,
        timeSlot: timeSlot,
        appointmentDate: appointmentDate,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        questionnaireAnswers: questionnaireAnswers,
      );

      await appointmentRef.set(appointment.toJson());

      print('✅ Appointment created successfully: ${appointment.id}');
      return appointment;
    } on FirebaseException catch (e) {
      throw BookingException(
        'فشل في إنشاء الموعد: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في إنشاء الموعد');
    }
  }

  @override
  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return querySnapshot.docs
          .map((doc) => Appointment.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } on TimeoutException {
      throw const BookingException(
        'انتهت مهلة الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        code: 'FIRESTORE_TIMEOUT',
      );
    } on FirebaseException catch (firestoreError) {
      if (firestoreError.code == 'permission-denied') {
        throw const BookingException(
          'لا توجد صلاحيات للقراءة من قاعدة البيانات. يرجى التحقق من قواعد الأمان.',
          code: 'FIRESTORE_PERMISSION_DENIED',
        );
      } else {
        throw BookingException(
          'خطأ في قاعدة البيانات: ${firestoreError.message}',
          code: firestoreError.code,
        );
      }
    } catch (e) {
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في جلب المواعيد');
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      print('✅ Appointment cancelled successfully: $appointmentId');
    } on FirebaseException catch (e) {
      throw BookingException(
        'فشل في إلغاء الموعد: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في إلغاء الموعد');
    }
  }

  @override
  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      final docRef = _firestore.collection('appointments').doc(appointmentId);

      await docRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await docRef.get();
      if (!updatedDoc.exists) {
        throw const BookingException('الموعد غير موجود');
      }

      final updatedData = updatedDoc.data()!;
      updatedData['id'] = updatedDoc.id;

      return Appointment.fromJson(updatedData);
    } on FirebaseException catch (e) {
      throw BookingException(
        'فشل في تحديث حالة الموعد: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw const BookingException('فشل في تحديث حالة الموعد');
    }
  }

  /// Convert AppUser to Doctor model
  Doctor _convertAppUserToDoctor(Map<String, dynamic> userData) {
    return Doctor(
      id: userData['id'] as String,
      name: userData['name'] as String,
      specialization: 'طب عام', // Default specialization, can be enhanced later
      rating: 4.5, // Default rating, can be enhanced later
      availability: 'متاح', // Default availability
      imageUrl: '', // No image for now
      description: 'طبيب متخصص في الرعاية الطبية العامة',
      availableTimeSlots: [
        '09:00',
        '10:00',
        '11:00',
        '14:00',
        '15:00',
        '16:00',
      ],
    );
  }

  /// Convert Firebase error codes to Arabic error messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية للوصول إلى هذه البيانات';
      case 'not-found':
        return 'البيانات غير موجودة';
      case 'already-exists':
        return 'البيانات موجودة بالفعل';
      case 'resource-exhausted':
        return 'تم استنفاد الموارد، يرجى المحاولة لاحقاً';
      case 'failed-precondition':
        return 'فشل في الشرط المسبق';
      case 'aborted':
        return 'تم إلغاء العملية';
      case 'out-of-range':
        return 'القيمة خارج النطاق المسموح';
      case 'unimplemented':
        return 'الميزة غير مطبقة';
      case 'internal':
        return 'خطأ داخلي في الخادم';
      case 'unavailable':
        return 'الخدمة غير متاحة حالياً';
      case 'data-loss':
        return 'فقدان البيانات';
      case 'unauthenticated':
        return 'غير مصادق عليه';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
