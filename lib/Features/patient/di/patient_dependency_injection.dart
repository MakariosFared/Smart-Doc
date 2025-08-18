import 'package:smart_doc/Features/patient/domain/repositories/booking_repository.dart';
import '../domain/repositories/questionnaire_repository.dart';
import '../domain/repositories/survey_repository.dart';
import '../data/repositories/mock_booking_repository_impl.dart';
import '../data/repositories/mock_questionnaire_repository_impl.dart';
import '../data/repositories/firebase_survey_repository_impl.dart';

/// Dependency injection for patient features
class PatientDependencyInjection {
  static BookingRepository? _bookingRepository;
  static QuestionnaireRepository? _questionnaireRepository;
  static SurveyRepository? _surveyRepository;

  /// Get the BookingRepository instance
  static BookingRepository get bookingRepository {
    _bookingRepository ??= MockBookingRepositoryImpl();
    return _bookingRepository!;
  }

  /// Get the QuestionnaireRepository instance
  static QuestionnaireRepository get questionnaireRepository {
    _questionnaireRepository ??= MockQuestionnaireRepositoryImpl();
    return _questionnaireRepository!;
  }

  /// Get the SurveyRepository instance
  static SurveyRepository get surveyRepository {
    _surveyRepository ??= FirebaseSurveyRepositoryImpl();
    return _surveyRepository!;
  }

  /// Reset the repositories (useful for testing)
  static void reset() {
    _bookingRepository = null;
    _questionnaireRepository = null;
    _surveyRepository = null;
  }
}
