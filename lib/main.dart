import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_doc/firebase_options.dart';
import 'Features/auth/index.dart';
import 'Features/auth/presentation/view/role_selection_page.dart';
import 'Features/auth/presentation/view/login_page.dart';
import 'Features/auth/presentation/view/signup_page.dart';
import 'Features/patient/presentation/view/home_patient_page.dart';
import 'Features/patient/presentation/view/book_appointment_page.dart';
import 'Features/patient/presentation/view/queue_status_page.dart';

import 'Features/patient/presentation/view/questionnaire_screen.dart';
import 'Features/patient/presentation/view/survey_screen.dart';
import 'Features/patient/presentation/view/profile_page.dart';
import 'Features/doctor/presentation/view/doctor_home_screen.dart';
import 'Features/patient/presentation/cubit/booking_cubit.dart';
import 'Features/patient/presentation/cubit/questionnaire_cubit.dart';
import 'Features/patient/presentation/cubit/survey_cubit.dart';
import 'Features/patient/di/patient_dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartDoc());
}

class SmartDoc extends StatelessWidget {
  const SmartDoc({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepository: AuthDependencyInjection.authRepository),
        ),
        BlocProvider<BookingCubit>(
          create: (context) => BookingCubit(
            bookingRepository: PatientDependencyInjection.bookingRepository,
          ),
        ),
        BlocProvider<QuestionnaireCubit>(
          create: (context) => QuestionnaireCubit(
            questionnaireRepository:
                PatientDependencyInjection.questionnaireRepository,
          ),
        ),
        BlocProvider<SurveyCubit>(
          create: (context) => SurveyCubit(
            surveyRepository: PatientDependencyInjection.surveyRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Clinic Queue',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('ar'), // مؤقتًا خليها عربي، هنخليها dynamic بعدين
        initialRoute: '/',
        routes: {
          '/': (context) => const RoleSelectionPage(),
          '/login': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return LoginPage(role: args);
          },
          '/signup': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return SignupPage(role: args);
          },
          '/patient-home': (context) => const PatientHomeScreen(),
          '/doctor-home': (context) => const DoctorHomeScreen(),

          // Patient Feature Routes
          '/patient/book-appointment': (context) => const BookAppointmentPage(),
          '/patient/queue-status': (context) => const QueueStatusPage(),

          '/patient/questionnaire-screen': (context) =>
              const QuestionnaireScreen(),
          '/patient/survey': (context) => const SurveyScreen(),
          '/patient/profile': (context) => const ProfilePage(),
        },
      ),
    );
  }
}
