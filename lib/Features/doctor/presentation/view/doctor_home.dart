import 'package:flutter/material.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = [
      {"name": "محمد", "symptoms": "صداع + حمى", "status": "waiting"},
      {"name": "أحمد", "symptoms": "دوخة", "status": "waiting"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("واجهة الدكتور")),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            child: ListTile(
              title: Text(patient["name"]!),
              subtitle: Text(patient["symptoms"]!),
              trailing: ElevatedButton(
                onPressed: () {
                  // هنا ممكن تغير حالة المريض في Firestore
                },
                child: const Text("بدأ الكشف"),
              ),
            ),
          );
        },
      ),
    );
  }
}
