import 'package:flutter/material.dart';
import 'common_app_bar.dart';
import 'custom_button.dart';

class HomePageTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color themeColor;
  final List<Widget>? additionalWidgets;
  final VoidCallback? onLogout;

  const HomePageTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeColor,
    this.additionalWidgets,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: title,
        backgroundColor: themeColor,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: themeColor),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "هذه صفحة مؤقتة - سيتم إضافة الميزات لاحقاً",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (additionalWidgets != null) ...[
                const SizedBox(height: 40),
                ...additionalWidgets!,
              ],
              const SizedBox(height: 40),
              CustomButton(
                text: "تسجيل الخروج",
                onPressed:
                    onLogout ??
                    () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                type: ButtonType.danger,
                icon: Icons.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
