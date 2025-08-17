import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/home_page_template.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageTemplate(
      title: "Doctor Home",
      subtitle: "مرحباً بك في صفحة الدكتور",
      icon: Icons.medical_services,
      themeColor: Colors.green,
      additionalWidgets: [
        // Add any doctor-specific widgets here
        // Example: Patient queue, appointments, etc.
      ],
    );
  }
}
