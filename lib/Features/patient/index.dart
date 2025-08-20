// Data Models
export 'data/models/doctor.dart';
export 'data/models/appointment.dart';
export 'data/models/questionnaire.dart';
export 'data/models/survey_model.dart';

// Repositories
export 'data/repositories/booking_repository.dart';
export 'data/repositories/questionnaire_repository.dart';
export 'data/repositories/survey_repository.dart';
export 'data/repositories/mock_booking_repository_impl.dart';
export 'data/repositories/mock_questionnaire_repository_impl.dart';
export 'data/repositories/firebase_survey_repository_impl.dart';

// Cubits (ViewModels)
export 'presentation/cubit/booking_cubit.dart';
export 'presentation/cubit/booking_state.dart';
export 'presentation/cubit/questionnaire_cubit.dart';
export 'presentation/cubit/questionnaire_state.dart';
export 'presentation/cubit/survey_cubit.dart';

// Views
export 'presentation/view/questionnaire_screen.dart';
export 'presentation/view/survey_screen.dart';
export 'presentation/view/questionnaire_summary_page.dart';
export 'presentation/view/book_appointment_page.dart';
export 'presentation/view/home_patient_page.dart';
export 'presentation/view/profile_page.dart';

// Note: PatientQueuePage is now exported from the queue feature
// Use: import 'package:smart_doc/Features/queue/presentation/view/patient_queue_page.dart';
