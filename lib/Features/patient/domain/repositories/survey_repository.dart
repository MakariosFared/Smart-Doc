import '../entities/survey.dart';

abstract class SurveyRepository {
  /// Submit a survey response for a patient
  Future<Survey> submitSurvey({
    required String patientId,
    required String doctorId,
    required SurveyData surveyData,
  });

  /// Get survey response for a specific patient and doctor
  Future<Survey?> getSurveyResponse({
    required String patientId,
    required String doctorId,
  });

  /// Get all survey responses for a patient
  Future<List<Survey>> getPatientSurveys(String patientId);

  /// Get all survey responses for a doctor
  Future<List<Survey>> getDoctorSurveys(String doctorId);

  /// Check if a patient has completed a survey for a specific doctor
  Future<bool> hasCompletedSurvey({
    required String patientId,
    required String doctorId,
  });
}

/// Custom exception for survey errors
class SurveyException implements Exception {
  final String message;
  final String? code;

  const SurveyException(this.message, {this.code});

  @override
  String toString() =>
      'SurveyException: $message${code != null ? ' (Code: $code)' : ''}';
}
