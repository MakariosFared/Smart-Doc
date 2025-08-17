import 'package:flutter/material.dart';
import 'widgets/role_selection_card.dart';
import 'widgets/common_app_bar.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "اختر نوع الحساب",
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "مرحباً بك في تطبيق العيادة الذكية",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: RoleSelectionCard(
                      title: "مريض",
                      subtitle: "تسجيل الدخول كمريض",
                      icon: Icons.person,
                      color: Colors.blue,
                      onPressed: () => _navigateToLogin(context, 'patient'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RoleSelectionCard(
                      title: "دكتور",
                      subtitle: "تسجيل الدخول كدكتور",
                      icon: Icons.medical_services,
                      color: Colors.green,
                      onPressed: () => _navigateToLogin(context, 'doctor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.pushNamed(context, '/login', arguments: role);
  }
}
