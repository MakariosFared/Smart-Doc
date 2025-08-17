import 'package:flutter/material.dart';
import 'package:smart_doc/Features/queue/presentation/view/queue_screen.dart';
import 'patient_form.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("واجهة المريض")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientForm()),
                );
              },
              child: const Text("إدخال بياناتي + الاستبيان"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QueueScreen()),
                );
              },
              child: const Text("عرض دوري في الطابور"),
            ),
          ],
        ),
      ),
    );
  }
}
