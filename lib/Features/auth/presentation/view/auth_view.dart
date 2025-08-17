import 'package:flutter/material.dart';
import 'package:smart_doc/Features/doctor/presentation/view/doctor_home.dart';
import 'package:smart_doc/Features/patient/presentation/view/patient_home.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الدخول")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // هنا ممكن تضيف Firebase Auth (بالتليفون أو إيميل)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientHome()),
                );
              },
              child: const Text("الدخول كمريض"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHome()),
                );
              },
              child: const Text("الدخول كدكتور"),
            ),
          ],
        ),
      ),
    );
  }
}
