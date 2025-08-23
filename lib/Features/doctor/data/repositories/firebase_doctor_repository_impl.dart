import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_doc/Features/doctor/data/models/doctor_queue_patient.dart';
import '../repositories/doctor_repository.dart';
import '../../../queue/data/models/queue_entry_model.dart';
import '../../../patient/data/models/survey_model.dart';

class FirebaseDoctorRepositoryImpl implements DoctorRepository {
  final FirebaseFirestore _firestore;

  FirebaseDoctorRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<DoctorQueuePatient>> getDoctorQueueStream(String doctorId) {
    return _firestore
        .collection('queues')
        .doc(doctorId)
        .collection('patients')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          final patients = <DoctorQueuePatient>[];
          int queueNumber = 1;

          for (final doc in snapshot.docs) {
            final entry = QueueEntry.fromJson({'id': doc.id, ...doc.data()});

            // Only include active patients (waiting or in progress)
            if (entry.isActive) {
              patients.add(
                DoctorQueuePatient.fromQueueEntry(entry, queueNumber),
              );
              queueNumber++;
            }
          }

          return patients;
        });
  }

  @override
  Future<DoctorQueuePatient?> getCurrentPatient(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .where('status', isEqualTo: 'inProgress')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      final entry = QueueEntry.fromJson({'id': doc.id, ...doc.data()});

      return DoctorQueuePatient.fromQueueEntry(entry, 1);
    } catch (e) {
      throw DoctorException('فشل في جلب المريض الحالي: $e');
    }
  }

  @override
  Future<void> startServingPatient(String doctorId, String patientId) async {
    try {
      // Update patient status to in progress
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .update({
            'status': 'inProgress',
            'startedAt': FieldValue.serverTimestamp(),
          });

      // Send notification to patient (this would be handled by FCM service)
      print('✅ Patient $patientId started being served by doctor $doctorId');
    } catch (e) {
      throw DoctorException('فشل في بدء خدمة المريض: $e');
    }
  }

  @override
  Future<void> completePatient(String doctorId, String patientId) async {
    try {
      // Mark patient as done
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .update({
            'status': 'done',
            'completedAt': FieldValue.serverTimestamp(),
          });

      // Send notification to patient
      print('✅ Patient $patientId completed by doctor $doctorId');
    } catch (e) {
      throw DoctorException('فشل في إكمال خدمة المريض: $e');
    }
  }

  @override
  Future<void> skipPatient(String doctorId, String patientId) async {
    try {
      // Move patient to end of queue by updating timestamp
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .update({
            'timestamp': FieldValue.serverTimestamp(),
            'skippedAt': FieldValue.serverTimestamp(),
            'skippedBy': doctorId,
          });

      // Send notification to patient
      print('⚠️ Patient $patientId skipped by doctor $doctorId');
    } catch (e) {
      throw DoctorException('فشل في تخطي المريض: $e');
    }
  }

  @override
  Future<Survey?> getPatientQuestionnaire(
    String patientId,
    String doctorId,
  ) async {
    try {
      print(
        '🔍 Fetching questionnaire for patient $patientId from doctor $doctorId',
      );

      final querySnapshot = await _firestore
          .collection('surveys')
          .doc(doctorId)
          .collection(patientId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      print('📊 Found ${querySnapshot.docs.length} questionnaire documents');

      if (querySnapshot.docs.isEmpty) {
        print(
          '⚠️ No questionnaire found for patient $patientId from doctor $doctorId',
        );
        return null;
      }

      final doc = querySnapshot.docs.first;
      print('✅ Found questionnaire document: ${doc.id}');

      final data = doc.data();
      print('📋 Questionnaire data keys: ${data.keys.toList()}');

      return SurveyModel.fromJson({'id': doc.id, ...data});
    } catch (e) {
      print('❌ Error fetching questionnaire: $e');
      throw DoctorException('فشل في جلب استبيان المريض: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getPatientMedicalHistory(
    String patientId,
  ) async {
    try {
      // This would typically fetch from a medical history collection
      // For now, return a mock structure
      return {
        'lastVisit': DateTime.now().subtract(const Duration(days: 30)),
        'chronicConditions': [],
        'allergies': [],
        'medications': [],
        'notes': 'لا توجد سجلات طبية سابقة',
      };
    } catch (e) {
      throw DoctorException('فشل في جلب التاريخ الطبي: $e');
    }
  }

  @override
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': doctorId,
          });

      print(
        '✅ Patient $patientId status updated to $status by doctor $doctorId',
      );
    } catch (e) {
      throw DoctorException('فشل في تحديث حالة المريض: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getQueueStatistics(String doctorId) async {
    try {
      print('🔍 Getting queue statistics for doctor: $doctorId');

      final querySnapshot = await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .get();

      print('📊 Found ${querySnapshot.docs.length} patients in queue');

      int totalPatients = 0;
      int waitingPatients = 0;
      int inProgressPatients = 0;
      int completedPatients = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final entry = QueueEntry.fromJson({'id': doc.id, ...doc.data()});
          totalPatients++;

          switch (entry.status) {
            case QueueStatus.waiting:
              waitingPatients++;
              break;
            case QueueStatus.inProgress:
              inProgressPatients++;
              break;
            case QueueStatus.done:
              completedPatients++;
              break;
            case QueueStatus.cancelled:
              // Don't count cancelled patients
              break;
          }
        } catch (e) {
          print('⚠️ Error processing patient document ${doc.id}: $e');
          print('⚠️ Document data: ${doc.data()}');
          // Continue with other documents
        }
      }

      print(
        '📈 Queue statistics: total=$totalPatients, waiting=$waitingPatients, inProgress=$inProgressPatients, completed=$completedPatients',
      );

      return {
        'totalPatients': totalPatients,
        'waitingPatients': waitingPatients,
        'inProgressPatients': inProgressPatients,
        'completedPatients': completedPatients,
        'averageWaitTime': _calculateAverageWaitTime(querySnapshot.docs),
      };
    } catch (e) {
      print('❌ Error in getQueueStatistics: $e');
      throw DoctorException('فشل في جلب إحصائيات الطابور: $e');
    }
  }

  Duration _calculateAverageWaitTime(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return Duration.zero;

    print('🔍 Calculating average wait time for ${docs.length} documents');

    int totalWaitTime = 0;
    int count = 0;

    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        // Handle different timestamp formats from Firestore
        DateTime? joinedAt;
        DateTime? completedAt;

        // Handle timestamp field (could be Timestamp, String, or null)
        if (data['timestamp'] != null) {
          print(
            '🔍 Processing timestamp: ${data['timestamp']} (type: ${data['timestamp'].runtimeType})',
          );
          if (data['timestamp'] is Timestamp) {
            joinedAt = (data['timestamp'] as Timestamp).toDate();
            print('✅ Parsed Timestamp: $joinedAt');
          } else if (data['timestamp'] is String) {
            try {
              joinedAt = DateTime.parse(data['timestamp'] as String);
              print('✅ Parsed String timestamp: $joinedAt');
            } catch (e) {
              print(
                '⚠️ Could not parse timestamp string: ${data['timestamp']}',
              );
              continue;
            }
          } else {
            print(
              '⚠️ Unknown timestamp type: ${data['timestamp'].runtimeType}',
            );
          }
        }

        // Handle completedAt field (could be Timestamp, String, or null)
        if (data['completedAt'] != null) {
          print(
            '🔍 Processing completedAt: ${data['completedAt']} (type: ${data['completedAt'].runtimeType})',
          );
          if (data['completedAt'] is Timestamp) {
            completedAt = (data['completedAt'] as Timestamp).toDate();
            print('✅ Parsed completedAt Timestamp: $completedAt');
          } else if (data['completedAt'] is String) {
            try {
              completedAt = DateTime.parse(data['completedAt'] as String);
              print('✅ Parsed completedAt String: $completedAt');
            } catch (e) {
              print(
                '⚠️ Could not parse completedAt string: ${data['completedAt']}',
              );
              continue;
            }
          } else {
            print(
              '⚠️ Unknown completedAt type: ${data['completedAt'].runtimeType}',
            );
          }
        }

        if (joinedAt != null && completedAt != null) {
          final waitTime = completedAt.difference(joinedAt);
          totalWaitTime += waitTime.inMinutes;
          count++;
          print('✅ Calculated wait time: ${waitTime.inMinutes} minutes');
        }
      } catch (e) {
        print('⚠️ Error processing document ${doc.id}: $e');
        continue;
      }
    }

    if (count == 0) {
      print('⚠️ No valid wait times calculated');
      return Duration.zero;
    }

    final averageMinutes = totalWaitTime ~/ count;
    print(
      '📊 Average wait time: $averageMinutes minutes (from $count patients)',
    );
    return Duration(minutes: averageMinutes);
  }
}
