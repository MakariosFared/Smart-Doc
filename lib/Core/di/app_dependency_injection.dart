import 'package:smart_doc/Features/auth/data/repositories/auth_repository.dart';
import 'package:smart_doc/Features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/booking_repository.dart';
import 'package:smart_doc/Features/patient/data/repositories/questionnaire_repository.dart';
import 'package:smart_doc/Features/patient/data/repositories/survey_repository.dart';
import 'package:smart_doc/Features/queue/data/repositories/firebase_queue_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/firebase_survey_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/mock_booking_repository_impl.dart';
import 'package:smart_doc/Features/patient/data/repositories/mock_questionnaire_repository_impl.dart';
import 'package:smart_doc/Features/queue/data/repositories/queue_repository.dart';

/// Centralized dependency injection for the entire application
class AppDependencyInjection {
  // Singleton instances
  static AppDependencyInjection? _instance;
  static AppDependencyInjection get instance =>
      _instance ??= AppDependencyInjection._();

  AppDependencyInjection._();

  // Auth Dependencies
  static AuthRepository? _authRepository;
  static AuthRepository get authRepository {
    _authRepository ??= FirebaseAuthRepositoryImpl();
    return _authRepository!;
  }

  // Queue Dependencies
  static QueueRepository? _queueRepository;
  static QueueRepository get queueRepository {
    _queueRepository ??= FirebaseQueueRepositoryImpl();
    return _queueRepository!;
  }

  // Patient Dependencies
  static BookingRepository? _bookingRepository;
  static BookingRepository get bookingRepository {
    _bookingRepository ??= MockBookingRepositoryImpl();
    return _bookingRepository!;
  }

  static QuestionnaireRepository? _questionnaireRepository;
  static QuestionnaireRepository get questionnaireRepository {
    _questionnaireRepository ??= MockQuestionnaireRepositoryImpl();
    return _questionnaireRepository!;
  }

  static SurveyRepository? _surveyRepository;
  static SurveyRepository get surveyRepository {
    _surveyRepository ??= FirebaseSurveyRepositoryImpl();
    return _surveyRepository!;
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    _authRepository = null;
    _queueRepository = null;
    _bookingRepository = null;
    _questionnaireRepository = null;
    _surveyRepository = null;
  }

  /// Initialize all dependencies
  static Future<void> initialize() async {
    // Pre-initialize repositories if needed
    // This can be used for warm-up operations
    try {
      // Initialize auth repository
      await authRepository.isAuthenticated();

      print('All dependencies initialized successfully');
    } catch (e) {
      print('Warning: Some dependencies failed to initialize: $e');
    }
  }
}
