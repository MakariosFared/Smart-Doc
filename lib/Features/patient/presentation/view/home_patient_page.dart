import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/home_page_template.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageTemplate(
      title: "Patient Home",
      subtitle: "مرحباً بك في صفحة المريض",
      icon: Icons.person,
      themeColor: Colors.blue,
      additionalWidgets: [
        // Add any patient-specific widgets here
        // Example: Quick actions, recent appointments, etc.
      ],
    );
  }
}
