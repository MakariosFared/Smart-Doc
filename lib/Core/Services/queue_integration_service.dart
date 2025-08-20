

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
      // Get current user to get patient name
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if patient is already in queue for this doctor
      final existingEntry = await _queueRepository.getPatientQueuePosition(
        survey.doctorId,
        survey.patientId,
      );

      if (existingEntry != null) {
        // Patient is already in queue, return existing entry
        return existingEntry;
      }

      // Add patient to queue automatically
      final queueEntry = await _queueRepository.joinQueue(
        survey.doctorId,
        survey.patientId,
        currentUser.name,
      );

      return queueEntry;
    } catch (e) {
      // Log error but don't fail the survey completion
      print('Failed to auto-join queue after survey: $e');
      return null;
    }
  }

  /// Get patient's current queue status across all doctors
  Future<List<QueueEntry>> getPatientQueueStatus(String patientId) async {
    try {
      // This would require a more complex query to get all queues for a patient
      // For now, we'll return an empty list
      // In a real implementation, you might want to use a collection group query
      return [];
    } catch (e) {
      print('Failed to get patient queue status: $e');
      return [];
    }
  }

  /// Check if patient is in any active queue
  Future<bool> isPatientInAnyQueue(String patientId) async {
    try {
      final queues = await getPatientQueueStatus(patientId);
      return queues.any((queue) => queue.isActive);
    } catch (e) {
      print('Failed to check if patient is in any queue: $e');
      return false;
    }
  }

  /// Get estimated wait time for a patient in queue
  Future<int?> getEstimatedWaitTime(String doctorId, String patientId) async {
    try {
      final queue = await _queueRepository.getDoctorQueue(doctorId);
      final patientPosition = queue.indexWhere((q) => q.patientId == patientId);

      if (patientPosition == -1) return null;

      // Estimate 10 minutes per patient ahead in queue
      final estimatedMinutes = (patientPosition + 1) * 10;
      return estimatedMinutes;
    } catch (e) {
      print('Failed to get estimated wait time: $e');
      return null;
    }
  }
}
