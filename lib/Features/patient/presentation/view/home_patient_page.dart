import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/home_page_template.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../../../auth/presentation/view/widgets/role_selection_card.dart';

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
        _PatientWelcomeSection(),
        SizedBox(height: 30),
        _PatientNavigationGrid(),
      ],
    );
  }
}

class _PatientWelcomeSection extends StatelessWidget {
  const _PatientWelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            "أهلاً وسهلاً بك",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "أحمد محمد",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "مريض",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PatientNavigationGrid extends StatelessWidget {
  const _PatientNavigationGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "حجز موعد",
                subtitle: "احجز موعد مع الدكتور",
                icon: Icons.calendar_today,
                color: Colors.green,
                onTap: () =>
                    Navigator.pushNamed(context, '/patient/book-appointment'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NavigationCard(
                title: "حالة الطابور",
                subtitle: "تحقق من دورك",
                icon: Icons.queue,
                color: Colors.orange,
                onTap: () =>
                    Navigator.pushNamed(context, '/patient/queue-status'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "الاستبيان",
                subtitle: "أكمل الاستبيان الطبي",
                icon: Icons.quiz,
                color: Colors.purple,
                onTap: () =>
                    Navigator.pushNamed(context, '/patient/questionnaire'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NavigationCard(
                title: "الملف الشخصي",
                subtitle: "عرض وتعديل بياناتك",
                icon: Icons.person_outline,
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/patient/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
