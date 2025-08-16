import 'package:flutter/material.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // مبدئيًا هنعملها static، بعدين نربطها بـ Firestore
    final patients = [
      {"number": 1, "name": "محمد"},
      {"number": 2, "name": "أحمد"},
      {"number": 3, "name": "سارة"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("الطابور")),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return ListTile(
            title: Text("رقم ${patient['number']} - ${patient['name']}"),
            leading: index == 0
                ? const Icon(Icons.person, color: Colors.red)
                : const Icon(Icons.person_outline),
          );
        },
      ),
    );
  }
}
