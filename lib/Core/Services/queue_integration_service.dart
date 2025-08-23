import 'package:smart_doc/Features/auth/data/repositories/auth_repository.dart';
import 'package:smart_doc/Features/patient/data/models/survey_model.dart';
import 'package:smart_doc/Features/queue/data/models/queue_entry_model.dart';
import 'package:smart_doc/Features/queue/data/repositories/queue_repository.dart';

/// Service that automatically integrates queue operations with other features
class QueueIntegrationService {
  final QueueRepository _queueRepository;
  final AuthRepository _authRepository;

  QueueIntegrationService({
    required QueueRepository queueRepository,
    required AuthRepository authRepository,
  }) : _queueRepository = queueRepository,
       _authRepository = authRepository;

  /// Automatically add patient to doctor's queue after survey completion
  /// This is called when a patient completes a survey for a specific doctor
  Future<QueueEntry?> autoJoinQueueAfterSurvey(Survey survey) async {
    try {
      if (survey.doctorId.isEmpty || survey.patientId.isEmpty) {
        print('❌ Error: Survey missing required data');
        return null;
      }

      // Get current user to get patient name
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        print('❌ Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print(
        '🔄 Auto-joining patient ${currentUser.name} to queue for doctor ${survey.doctorId}',
      );

      // Check if patient is already in queue for this doctor
      final existingEntry = await _queueRepository.getPatientQueueStatus(
        survey.patientId,
        survey.doctorId,
      );

      if (existingEntry != null) {
        print(
          'ℹ️ Patient ${currentUser.name} is already in queue for doctor ${survey.doctorId}',
        );
        return existingEntry;
      }

      // Add patient to queue automatically
      await _queueRepository.addPatientToQueue(
        survey.doctorId,
        survey.patientId,
        currentUser.name,
      );

      print('✅ Patient ${currentUser.name} automatically added to queue');

      // Return a placeholder entry since addPatientToQueue doesn't return QueueEntry
      return QueueEntry(
        id: survey.patientId,
        patientId: survey.patientId,
        patientName: currentUser.name,
        doctorId: survey.doctorId,
        status: QueueStatus.waiting,
        timestamp: DateTime.now(),
        queueNumber: 0, // Will be set by the repository
        joinedAt: DateTime.now(),
      );
    } catch (e) {
      // Log error but don't fail the survey completion
      print('❌ Failed to auto-join queue after survey: $e');
      return null;
    }
  }

  /// Get patient's current queue status across all doctors
  Future<List<QueueEntry>> getPatientQueueStatus(String patientId) async {
    try {
      if (patientId.isEmpty) {
        print('❌ Error: patientId cannot be empty');
        return [];
      }

      // This would require a more complex query to get all queues for a patient
      // For now, we'll return an empty list
      // In a real implementation, you might want to use a collection group query
      print('ℹ️ Getting patient queue status not implemented yet');
      return [];
    } catch (e) {
      print('❌ Failed to get patient queue status: $e');
      return [];
    }
  }

  /// Check if patient is in any active queue
  Future<bool> isPatientInAnyQueue(String patientId) async {
    try {
      if (patientId.isEmpty) {
        print('❌ Error: patientId cannot be empty');
        return false;
      }

      final queues = await getPatientQueueStatus(patientId);
      return queues.any((queue) => queue.isActive);
    } catch (e) {
      print('❌ Failed to check if patient is in any queue: $e');
      return false;
    }
  }

  /// Get estimated wait time for a patient in queue
  Future<int?> getEstimatedWaitTime(String doctorId, String patientId) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        print('❌ Error: doctorId and patientId cannot be empty');
        return null;
      }

      final queue = await _queueRepository.getDoctorQueue(doctorId);
      final patientPosition = queue.indexWhere((q) => q.patientId == patientId);

      if (patientPosition == -1) {
        print('ℹ️ Patient $patientId not found in queue for doctor $doctorId');
        return null;
      }

      // Estimate 10 minutes per patient ahead in queue
      final estimatedMinutes = (patientPosition + 1) * 10;
      print(
        '⏱️ Estimated wait time for patient $patientId: $estimatedMinutes minutes',
      );

      return estimatedMinutes;
    } catch (e) {
      print('❌ Failed to get estimated wait time: $e');
      return null;
    }
  }

  /// Remove patient from all queues (useful when patient cancels or completes)
  Future<void> removePatientFromAllQueues(String patientId) async {
    try {
      if (patientId.isEmpty) {
        print('❌ Error: patientId cannot be empty');
        return;
      }

      print('🔄 Removing patient $patientId from all queues');

      // This would require a collection group query to find all queues
      // For now, we'll implement a basic version
      // In a real implementation, you might want to use a collection group query

      // Get all doctors and check their queues
      // This is a simplified approach - in production you'd use a more efficient method

      print('ℹ️ Remove from all queues not fully implemented yet');
    } catch (e) {
      print('❌ Failed to remove patient from all queues: $e');
    }
  }

  /// Get queue statistics for a specific doctor
  Future<Map<String, dynamic>?> getDoctorQueueStatistics(
    String doctorId,
  ) async {
    try {
      if (doctorId.isEmpty) {
        print('❌ Error: doctorId cannot be empty');
        return null;
      }

      // Try to get statistics from the repository if it has the method
      try {
        // Use reflection or check if method exists
        final queue = await _queueRepository.getDoctorQueue(doctorId);

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
        print(
          '⚠️ Repository does not have getQueueStatistics method, calculating manually',
        );
        return null;
      }
    } catch (e) {
      print('❌ Failed to get doctor queue statistics: $e');
      return null;
    }
  }
}
