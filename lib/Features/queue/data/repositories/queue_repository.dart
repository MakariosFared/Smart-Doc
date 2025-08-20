import '../models/queue_entry_model.dart';

abstract class QueueRepository {
  /// Join a doctor's queue
  /// Returns the queue entry with assigned queue number
  Future<QueueEntry> joinQueue(
    String doctorId,
    String patientId,
    String patientName,
  );

  /// Get current queue position for a patient
  Future<QueueEntry?> getPatientQueuePosition(
    String doctorId,
    String patientId,
  );

  /// Get all patients in a doctor's queue
  Future<List<QueueEntry>> getDoctorQueue(String doctorId);

  /// Update queue status for a patient
  Future<void> updateQueueStatus(
    String doctorId,
    String patientId,
    QueueStatus status,
  );

  /// Remove patient from queue
  Future<void> leaveQueue(String doctorId, String patientId);

  /// Get current queue length for a doctor
  Future<int> getQueueLength(String doctorId);

  /// Get patient's position number in queue (1-based index)
  Future<int> getPatientQueuePositionNumber(String doctorId, String patientId);

  /// Stream to listen to queue updates for a specific patient
  Stream<QueueEntry?> listenToQueueUpdates(String doctorId, String patientId);

  /// Stream to listen to doctor's queue changes
  Stream<List<QueueEntry>> listenToDoctorQueue(String doctorId);

  /// Find all queues where a specific patient is present
  /// This method searches across all doctors' queues
  Future<List<QueueEntry>> findPatientQueues(String patientId);

  /// Check if the required Firestore collection group index is available
  Future<bool> isCollectionGroupIndexAvailable();

  /// Get instructions for creating the required Firestore index
  String getIndexCreationInstructions();
}

/// Custom exception for queue operations
class QueueException implements Exception {
  final String message;
  final String? code;

  const QueueException(this.message, {this.code});

  @override
  String toString() =>
      'QueueException: $message${code != null ? ' (Code: $code)' : ''}';
}
