import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'queue_repository.dart';
import '../models/queue_entry_model.dart';

class FirebaseQueueRepositoryImpl implements QueueRepository {
  final FirebaseFirestore _firestore;

  FirebaseQueueRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references - using new structure
  CollectionReference<Map<String, dynamic>> _getPatientsSubcollection(
    String doctorId,
  ) => _firestore.collection('queues').doc(doctorId).collection('patients');

  @override
  Future<QueueEntry> joinQueue(
    String doctorId,
    String patientId,
    String patientName,
  ) async {
    try {
      // Check if patient is already in queue
      final existingEntry = await getPatientQueuePosition(doctorId, patientId);
      if (existingEntry != null) {
        throw const QueueException('أنت موجود بالفعل في الطابور');
      }

      // Create queue entry
      final queueEntry = QueueEntry(
        id: _firestore.collection('_temp').doc().id, // Generate unique ID
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        status: QueueStatus.waiting,
        timestamp: DateTime.now(),
      );

      // Add to Firebase using new structure
      await _getPatientsSubcollection(
        doctorId,
      ).doc(queueEntry.id).set(queueEntry.toJson());

      return queueEntry;
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في الانضمام للطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في الانضمام للطابور: $e');
    }
  }

  @override
  Future<QueueEntry?> getPatientQueuePosition(
    String doctorId,
    String patientId,
  ) async {
    try {
      final querySnapshot = await _getPatientsSubcollection(doctorId)
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['waiting', 'inProgress'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return QueueEntry.fromJson({'id': doc.id, ...doc.data()});
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في جلب موقع الطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في جلب موقع الطابور: $e');
    }
  }

  @override
  Future<List<QueueEntry>> getDoctorQueue(String doctorId) async {
    try {
      final querySnapshot = await _getPatientsSubcollection(doctorId)
          .where('status', whereIn: ['waiting', 'inProgress'])
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs
          .map((doc) => QueueEntry.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في جلب الطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في جلب الطابور: $e');
    }
  }

  @override
  Future<void> updateQueueStatus(
    String doctorId,
    String patientId,
    QueueStatus status,
  ) async {
    try {
      final querySnapshot = await _getPatientsSubcollection(
        doctorId,
      ).where('patientId', isEqualTo: patientId).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        throw const QueueException('لم يتم العثور على المريض في الطابور');
      }

      final doc = querySnapshot.docs.first;
      await _getPatientsSubcollection(
        doctorId,
      ).doc(doc.id).update({'status': status.name});
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في تحديث حالة الطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في تحديث حالة الطابور: $e');
    }
  }

  @override
  Future<void> leaveQueue(String doctorId, String patientId) async {
    try {
      final querySnapshot = await _getPatientsSubcollection(
        doctorId,
      ).where('patientId', isEqualTo: patientId).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        throw const QueueException('لم يتم العثور على المريض في الطابور');
      }

      final doc = querySnapshot.docs.first;
      await _getPatientsSubcollection(
        doctorId,
      ).doc(doc.id).update({'status': QueueStatus.cancelled.name});
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في مغادرة الطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في مغادرة الطابور: $e');
    }
  }

  @override
  Future<int> getQueueLength(String doctorId) async {
    try {
      final querySnapshot = await _getPatientsSubcollection(
        doctorId,
      ).where('status', whereIn: ['waiting', 'inProgress']).count().get();

      return querySnapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw QueueException(
        'فشل في جلب طول الطابور: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في جلب طول الطابور: $e');
    }
  }

  @override
  Stream<QueueEntry?> listenToQueueUpdates(String doctorId, String patientId) {
    try {
      return _getPatientsSubcollection(
        doctorId,
      ).where('patientId', isEqualTo: patientId).snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final doc = snapshot.docs.first;
        return QueueEntry.fromJson({'id': doc.id, ...doc.data()});
      });
    } catch (e) {
      return Stream.error(
        QueueException('فشل في الاستماع لتحديثات الطابور: $e'),
      );
    }
  }

  @override
  Stream<List<QueueEntry>> listenToDoctorQueue(String doctorId) {
    try {
      return _getPatientsSubcollection(doctorId)
          .where('status', whereIn: ['waiting', 'inProgress'])
          .orderBy('timestamp')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => QueueEntry.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList(),
          );
    } catch (e) {
      return Stream.error(
        QueueException('فشل في الاستماع لتحديثات الطابور: $e'),
      );
    }
  }

  /// Get patient's position in queue (1-based index)
  Future<int> getPatientQueuePositionNumber(
    String doctorId,
    String patientId,
  ) async {
    try {
      final queue = await getDoctorQueue(doctorId);
      final patientIndex = queue.indexWhere(
        (entry) => entry.patientId == patientId,
      );
      return patientIndex >= 0 ? patientIndex + 1 : -1;
    } catch (e) {
      throw QueueException('فشل في جلب موقع المريض في الطابور: $e');
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

  /// Check if the required collection group index is available
  Future<bool> isCollectionGroupIndexAvailable() async {
    try {
      // Try a simple collection group query to see if the index exists
      await _firestore.collectionGroup('patients').limit(1).get();
      print('✅ Firestore collection group index is available');
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        print('❌ Firestore collection group index is NOT available');
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
        print('Index creation instructions:');
        print(getIndexCreationInstructions());
        return false;
      }
      // Other errors might indicate different issues
      print('⚠️ Firestore error (not index-related): ${e.code} - ${e.message}');
      return true;
    } catch (e) {
      // Other errors, assume index might be available
      print('⚠️ Unexpected error checking index: $e');
      return true;
    }
  }

  /// Get instructions for creating the required Firestore index
  String getIndexCreationInstructions() {
    return '''
Firestore requires a composite index for collection group queries.

To create the required index:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: smart-doc-1d42f
3. Go to Firestore Database → Indexes
4. Click "Create Index"
5. Collection ID: patients (as a collection group)
6. Fields:
   - patientId (Ascending)
   - status (Ascending)
   - __name__ (Ascending)
7. Click "Create"

Or use this direct link:
https://console.firebase.google.com/v1/r/project/smart-doc-1d42f/firestore/indexes?create_composite=ClBwcm9qZWN0cy9zbWFydC1kb2MtMWQ0MmYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhdGllbnRzL2luZGV4ZXNvXxACGg0KCXBhdGllbnRJZBABGgoKBnN0YXR1cxABGgwKCF9fbmFtZV9fEAE

The app will work with an alternative query method until the index is created.
''';
  }

  @override
  Future<List<QueueEntry>> findPatientQueues(String patientId) async {
    try {
      // Use collection group query to search across all subcollections
      // This will search in all 'patients' subcollections under 'queues' collection
      final querySnapshot = await _firestore
          .collectionGroup('patients')
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['waiting', 'inProgress'])
          .get();

      return querySnapshot.docs
          .map((doc) => QueueEntry.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Index not created yet, try alternative approach
        print(
          'Firestore index not created, trying alternative query approach...',
        );
        return await _findPatientQueuesAlternative(patientId);
      }
      throw QueueException(
        'فشل في البحث عن طوابير المريض: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      if (e is QueueException) rethrow;
      throw QueueException('فشل في البحث عن طوابير المريض: $e');
    }
  }

  /// Alternative method to find patient queues when the collection group index is not available
  Future<List<QueueEntry>> _findPatientQueuesAlternative(
    String patientId,
  ) async {
    try {
      print('Using alternative query approach for patient: $patientId');

      // Get all doctors from the queues collection
      final doctorsSnapshot = await _firestore.collection('queues').get();
      final List<QueueEntry> allPatientQueues = [];

      // Search through each doctor's queue
      for (final doctorDoc in doctorsSnapshot.docs) {
        try {
          final patientsSnapshot = await doctorDoc.reference
              .collection('patients')
              .where('patientId', isEqualTo: patientId)
              .where('status', whereIn: ['waiting', 'inProgress'])
              .get();

          for (final patientDoc in patientsSnapshot.docs) {
            final data = patientDoc.data();
            // Add doctor ID to the data since we're searching across collections
            data['doctorId'] = doctorDoc.id;

            final queueEntry = QueueEntry.fromJson({
              'id': patientDoc.id,
              ...data,
            });
            allPatientQueues.add(queueEntry);
          }
        } catch (e) {
          // Skip this doctor if there's an error, continue with others
          print('Error searching in doctor ${doctorDoc.id}: $e');
          continue;
        }
      }

      print(
        'Alternative search found ${allPatientQueues.length} queues for patient: $patientId',
      );
      return allPatientQueues;
    } catch (e) {
      print('Alternative search also failed: $e');
      throw QueueException(
        'فشل في البحث عن طوابير المريض (الطريقة البديلة): $e',
        code: 'ALTERNATIVE_QUERY_FAILED',
      );
    }
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
