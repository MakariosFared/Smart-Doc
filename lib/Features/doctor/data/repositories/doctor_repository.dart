import 'package:smart_doc/Features/doctor/data/models/doctor_queue_patient.dart';

import '../../../patient/data/models/survey_model.dart';

abstract class DoctorRepository {
  /// Get real-time stream of patients in doctor's queue
  Stream<List<DoctorQueuePatient>> getDoctorQueueStream(String doctorId);

  /// Get current patient being served
  Future<DoctorQueuePatient?> getCurrentPatient(String doctorId);

  /// Start serving a patient (mark as in progress)
  Future<void> startServingPatient(String doctorId, String patientId);

  /// Mark patient as done and move to next
  Future<void> completePatient(String doctorId, String patientId);

  /// Skip patient and move to end of queue
  Future<void> skipPatient(String doctorId, String patientId);

  /// Get patient's questionnaire/survey data
  Future<Survey?> getPatientQuestionnaire(String patientId, String doctorId);

  /// Get patient's medical history summary
  Future<Map<String, dynamic>?> getPatientMedicalHistory(String patientId);

  /// Update patient status in queue
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    String status,
  );

  /// Get queue statistics for doctor
  Future<Map<String, dynamic>> getQueueStatistics(String doctorId);
}

/// Custom exception for doctor operations
class DoctorException implements Exception {
  final String message;
  final String? code;

  const DoctorException(this.message, {this.code});

  @override
  String toString() =>
      'DoctorException: $message${code != null ? ' (Code: $code)' : ''}';
}
