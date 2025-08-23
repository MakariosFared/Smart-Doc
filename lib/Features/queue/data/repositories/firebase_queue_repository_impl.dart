import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_entry_model.dart';
import '../repositories/queue_repository.dart';

class FirebaseQueueRepositoryImpl implements QueueRepository {
  final FirebaseFirestore _firestore;

  FirebaseQueueRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<QueueEntry>> getQueueStream(String doctorId) {
    if (doctorId.isEmpty) {
      print('❌ Error: doctorId cannot be empty');
      return Stream.value([]);
    }

    return _firestore
        .collection('queues')
        .doc(doctorId)
        .collection('patients')
        .orderBy('queueNumber', descending: false)
        .snapshots()
        .map((snapshot) {
          final entries = <QueueEntry>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;

              // Ensure required fields are present
              if (data['patientId'] == null || data['patientName'] == null) {
                print('⚠️ Skipping invalid queue entry: ${doc.id}');
                continue;
              }

              final entry = QueueEntry.fromJson(data);

              // Only add valid entries
              if (entry.isValid) {
                entries.add(entry);
              } else {
                print('⚠️ Skipping invalid queue entry: ${entry.id}');
              }
            } catch (e) {
              print('❌ Error parsing queue entry ${doc.id}: $e');
              print('❌ Document data: ${doc.data()}');
            }
          }

          print(
            '✅ Stream updated: ${entries.length} valid entries for doctor $doctorId',
          );
          return entries;
        })
        .handleError((error) {
          print('❌ Error in queue stream for doctor $doctorId: $error');
          return <QueueEntry>[];
        });
  }

  @override
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    QueueStatus newStatus,
  ) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        throw QueueException('doctorId and patientId cannot be empty');
      }

      print(
        '🔄 Updating patient $patientId status to ${newStatus.name} for doctor $doctorId',
      );

      // Update queue entry
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .update({
            'status': newStatus.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': doctorId,
          });

      // Also update the user's current status
      try {
        await _firestore.collection('users').doc(patientId).update({
          'currentQueueStatus': newStatus.name,
          'currentDoctorId': doctorId,
          'lastStatusUpdate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ Warning: Could not update user status: $e');
        // Don't fail the main operation if user update fails
      }

      print(
        '✅ Patient status updated successfully: $patientId -> ${newStatus.name}',
      );
    } catch (e) {
      print('❌ Error updating patient status: $e');
      throw QueueException('Failed to update patient status: $e');
    }
  }

  @override
  Future<void> addPatientToQueue(
    String doctorId,
    String patientId,
    String patientName,
  ) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty || patientName.isEmpty) {
        throw QueueException(
          'doctorId, patientId, and patientName cannot be empty',
        );
      }

      print(
        '🔄 Adding patient $patientName ($patientId) to queue for doctor $doctorId',
      );

      // Check if patient is already in queue
      final existingEntry = await getPatientQueueStatus(patientId, doctorId);
      if (existingEntry != null) {
        print('⚠️ Patient $patientId is already in queue for doctor $doctorId');
        return; // Patient already exists, don't add again
      }

      // Get the next queue number
      final queueSnapshot = await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .orderBy('queueNumber', descending: true)
          .limit(1)
          .get();

      int nextQueueNumber = 1;
      if (queueSnapshot.docs.isNotEmpty) {
        final lastEntry = queueSnapshot.docs.first.data();
        nextQueueNumber = (lastEntry['queueNumber'] ?? 0) + 1;
      }

      // Add patient to queue
      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .set({
            'patientId': patientId,
            'patientName': patientName,
            'doctorId': doctorId,
            'queueNumber': nextQueueNumber,
            'status': QueueStatus.waiting.name,
            'joinedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      print('✅ Patient added to queue: $patientName (Queue #$nextQueueNumber)');
    } catch (e) {
      print('❌ Error adding patient to queue: $e');
      throw QueueException('Failed to add patient to queue: $e');
    }
  }

  @override
  Future<void> removePatientFromQueue(String doctorId, String patientId) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        throw QueueException('doctorId and patientId cannot be empty');
      }

      print('🔄 Removing patient $patientId from queue for doctor $doctorId');

      await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .delete();

      // Also clear user's queue status
      try {
        await _firestore.collection('users').doc(patientId).update({
          'currentQueueStatus': null,
          'currentDoctorId': null,
          'lastStatusUpdate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ Warning: Could not clear user queue status: $e');
        // Don't fail the main operation if user update fails
      }

      print('✅ Patient removed from queue: $patientId');
    } catch (e) {
      print('❌ Error removing patient from queue: $e');
      throw QueueException('Failed to remove patient from queue: $e');
    }
  }

  @override
  Future<QueueEntry?> getPatientQueueStatus(
    String patientId,
    String doctorId,
  ) async {
    try {
      if (patientId.isEmpty || doctorId.isEmpty) {
        print('❌ Error: patientId and doctorId cannot be empty');
        return null;
      }

      final doc = await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .get();

      if (!doc.exists) {
        print('ℹ️ Patient $patientId not found in queue for doctor $doctorId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      final entry = QueueEntry.fromJson(data);

      if (!entry.isValid) {
        print('⚠️ Invalid queue entry data for patient $patientId');
        return null;
      }

      return entry;
    } catch (e) {
      print('❌ Error getting patient queue status: $e');
      return null;
    }
  }

  @override
  Future<List<QueueEntry>> getDoctorQueue(String doctorId) async {
    try {
      if (doctorId.isEmpty) {
        print('❌ Error: doctorId cannot be empty');
        return [];
      }

      print('🔄 Fetching queue for doctor $doctorId');

      final snapshot = await _firestore
          .collection('queues')
          .doc(doctorId)
          .collection('patients')
          .orderBy('queueNumber', descending: false)
          .get();

      final entries = <QueueEntry>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;

          final entry = QueueEntry.fromJson(data);

          if (entry.isValid) {
            entries.add(entry);
          } else {
            print('⚠️ Skipping invalid queue entry: ${entry.id}');
          }
        } catch (e) {
          print('❌ Error parsing queue entry ${doc.id}: $e');
          print('❌ Document data: ${doc.data()}');
        }
      }

      print('✅ Retrieved ${entries.length} queue entries for doctor $doctorId');
      return entries;
    } catch (e) {
      print('❌ Error getting doctor queue: $e');
      throw QueueException('Failed to get doctor queue: $e');
    }
  }

  /// Get queue statistics for a doctor
  Future<Map<String, dynamic>> getQueueStatistics(String doctorId) async {
    try {
      if (doctorId.isEmpty) {
        throw QueueException('doctorId cannot be empty');
      }

      final queue = await getDoctorQueue(doctorId);

      final waitingCount = queue
          .where((e) => e.status == QueueStatus.waiting)
          .length;
      final inProgressCount = queue
          .where((e) => e.status == QueueStatus.inProgress)
          .length;
      final completedCount = queue
          .where((e) => e.status == QueueStatus.done)
          .length;
      final cancelledCount = queue
          .where((e) => e.status == QueueStatus.cancelled)
          .length;

      return {
        'totalPatients': queue.length,
        'waitingPatients': waitingCount,
        'inProgressPatients': inProgressCount,
        'completedPatients': completedCount,
        'cancelledPatients': cancelledCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting queue statistics: $e');
      throw QueueException('Failed to get queue statistics: $e');
    }
  }
}
