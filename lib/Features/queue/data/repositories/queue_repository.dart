import '../models/queue_entry_model.dart';

abstract class QueueRepository {
  /// Get real-time stream of queue entries for a doctor
  Stream<List<QueueEntry>> getQueueStream(String doctorId);

  /// Update patient status in queue
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    QueueStatus newStatus,
  );

  /// Add patient to queue
  Future<void> addPatientToQueue(
    String doctorId,
    String patientId,
    String patientName,
  );

  /// Remove patient from queue
  Future<void> removePatientFromQueue(String doctorId, String patientId);

  /// Get patient's current queue status
  Future<QueueEntry?> getPatientQueueStatus(String patientId, String doctorId);

  /// Get doctor's queue (non-stream version)
  Future<List<QueueEntry>> getDoctorQueue(String doctorId);
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
