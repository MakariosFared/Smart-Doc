import 'package:smart_doc/Features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:smart_doc/Features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_doc/Features/patient/data/repositories/mock_booking_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/mock_questionnaire_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/firebase_survey_repository_impl.dart';
import 'package:smart_doc/Features/patient/domain/repositories/booking_repository.dart';
import 'package:smart_doc/Features/patient/domain/repositories/questionnaire_repository.dart';
import 'package:smart_doc/Features/patient/domain/repositories/survey_repository.dart';

/// Centralized dependency injection for the entire application
class DependencyInjection {
  // Auth dependencies
  static AuthRepository? _authRepository;

  // Patient feature dependencies
  static BookingRepository? _bookingRepository;
  static QuestionnaireRepository? _questionnaireRepository;
  static SurveyRepository? _surveyRepository;

  // Auth Repository
  static AuthRepository get authRepository {
    _authRepository ??= FirebaseAuthRepositoryImpl();
    return _authRepository!;
  }

  // Patient Feature Repositories
  static BookingRepository get bookingRepository {
    _bookingRepository ??= MockBookingRepositoryImpl();
    return _bookingRepository!;
  }

  static QuestionnaireRepository get questionnaireRepository {
    _questionnaireRepository ??= MockQuestionnaireRepositoryImpl();
    return _questionnaireRepository!;
  }

  static SurveyRepository get surveyRepository {
    _surveyRepository ??= FirebaseSurveyRepositoryImpl();
    return _surveyRepository!;
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    _authRepository = null;
    _bookingRepository = null;
    _questionnaireRepository = null;
    _surveyRepository = null;
  }
}
