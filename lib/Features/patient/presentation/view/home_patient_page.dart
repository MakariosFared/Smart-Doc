import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/home_page_template.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/data/models/app_user.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await context.read<AuthCubit>().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || _currentUser == null) {
          return const HomePageTemplate(
            title: "Patient Home",
            subtitle: "جاري التحميل...",
            icon: Icons.person,
            themeColor: Colors.blue,
            additionalWidgets: [Center(child: CircularProgressIndicator())],
          );
        }

        return HomePageTemplate(
          title: "Patient Home",
          subtitle: "مرحباً بك في صفحة المريض",
          icon: Icons.person,
          themeColor: Colors.blue,
          additionalWidgets: [
            _PatientWelcomeSection(user: _currentUser!),
            const SizedBox(height: 20),
            const _PatientNavigationGrid(),
          ],
        );
      },
    );
  }
}

class _PatientWelcomeSection extends StatelessWidget {
  final AppUser user;

  const _PatientWelcomeSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle, size: 50, color: Colors.blue),
          const SizedBox(height: 12),
          const Text(
            "أهلاً وسهلاً بك",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.roleDisplayName,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
            const SizedBox(width: 12), // Reduced from 16
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
        const SizedBox(height: 12), // Reduced from 16
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "الملف الشخصي",
                subtitle: "عرض وتعديل بياناتك",
                icon: Icons.person_outline,
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/patient/profile'),
              ),
            ),
            const SizedBox(width: 12), // Reduced from 16
            Expanded(
              child: _NavigationCard(
                title: "ملخص الاستبيان",
                subtitle: "عرض إجاباتك السابقة",
                icon: Icons.assignment_turned_in,
                color: Colors.indigo,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/patient/questionnaire-summary',
                  arguments: {
                    'doctorId': 'general',
                    'timeSlot': 'general',
                    'appointmentDate': DateTime.now(),
                    'isNewBooking': false,
                  },
                ),
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
          padding: const EdgeInsets.all(16), // Reduced from 20
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color), // Reduced from 50
              const SizedBox(height: 12), // Reduced from 16
              Text(
                title,
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ), // Reduced from 14
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
