import 'package:flutter/material.dart';

class PatientForm extends StatefulWidget {
  const PatientForm({super.key});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();

  String name = "";
  int age = 0;
  List<String> symptoms = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بيانات المريض")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "الاسم"),
              onSaved: (val) => name = val ?? "",
              validator: (val) =>
                  val == null || val.isEmpty ? "أدخل الاسم" : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "العمر"),
              keyboardType: TextInputType.number,
              onSaved: (val) => age = int.tryParse(val ?? "0") ?? 0,
            ),
            const SizedBox(height: 20),
            const Text("الأعراض:"),
            CheckboxListTile(
              title: const Text("صداع"),
              value: symptoms.contains("صداع"),
              onChanged: (val) {
                setState(() {
                  val! ? symptoms.add("صداع") : symptoms.remove("صداع");
                });
              },
            ),
            CheckboxListTile(
              title: const Text("حمى"),
              value: symptoms.contains("حمى"),
              onChanged: (val) {
                setState(() {
                  val! ? symptoms.add("حمى") : symptoms.remove("حمى");
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final formState = _formKey.currentState;
                if (formState != null && formState.validate()) {
                  formState.save();
                  // هنا هتخزن البيانات في Firestore
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حفظ البيانات")),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }
}
