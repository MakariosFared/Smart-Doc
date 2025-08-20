import '../models/questionnaire.dart';

abstract class QuestionnaireRepository {
  /// Get the medical questionnaire for patients
  Future<Questionnaire> getMedicalQuestionnaire();

  /// Submit questionnaire responses
  Future<QuestionnaireResponse> submitQuestionnaire({
    required String patientId,
    required Map<String, dynamic> answers,
  });

  /// Get questionnaire response by ID
  Future<QuestionnaireResponse?> getQuestionnaireResponse(String responseId);

  /// Get all questionnaire responses for a patient
  Future<List<QuestionnaireResponse>> getPatientQuestionnaireResponses(
    String patientId,
  );
}

/// Custom exception for questionnaire errors
class QuestionnaireException implements Exception {
  final String message;
  final String? code;

  const QuestionnaireException(this.message, {this.code});

  @override
  String toString() =>
      'QuestionnaireException: $message${code != null ? ' (Code: $code)' : ''}';
}
