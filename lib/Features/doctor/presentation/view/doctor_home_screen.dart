import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Features/auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/view/widgets/home_page_template.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/models/app_user.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  AppUser? _currentDoctor;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    final doctor = await context.read<AuthCubit>().getCurrentUser();
    if (doctor != null && mounted) {
      setState(() {
        _currentDoctor = doctor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || _currentDoctor == null) {
          return const HomePageTemplate(
            title: "Doctor Home",
            subtitle: "جاري التحميل...",
            icon: Icons.medical_services,
            themeColor: Colors.green,
            additionalWidgets: [Center(child: CircularProgressIndicator())],
          );
        }

        return HomePageTemplate(
          title: "Doctor Home",
          subtitle: "مرحباً بك في صفحة الدكتور",
          icon: Icons.medical_services,
          themeColor: Colors.green,
          additionalWidgets: [
            _DoctorWelcomeSection(user: _currentDoctor!),
            const SizedBox(height: 20),
            const _DoctorNavigationGrid(),
          ],
        );
      },
    );
  }
}

class _DoctorWelcomeSection extends StatelessWidget {
  final AppUser user;

  const _DoctorWelcomeSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.medical_services, size: 50, color: Colors.green),
          const SizedBox(height: 12),
          const Text(
            "أهلاً وسهلاً بك",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
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

class _DoctorNavigationGrid extends StatelessWidget {
  const _DoctorNavigationGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "إدارة الطابور",
                subtitle: "عرض وإدارة مرضى الطابور",
                icon: Icons.queue,
                color: Colors.blue,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/doctor/queue-home',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NavigationCard(
                title: "المواعيد",
                subtitle: "إدارة المواعيد والجداول",
                icon: Icons.calendar_today,
                color: Colors.orange,
                onTap: () {
                  // TODO: Implement appointments page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("سيتم إضافة هذه الميزة قريباً"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "التقارير",
                subtitle: "عرض التقارير والإحصائيات",
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () {
                  // TODO: Implement reports page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("سيتم إضافة هذه الميزة قريباً"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NavigationCard(
                title: "قائمة الأطباء",
                subtitle: "عرض جميع الأطباء المسجلين",
                icon: Icons.people,
                color: Colors.indigo,
                onTap: () => Navigator.pushNamed(context, '/doctors-list'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                title: "الإعدادات",
                subtitle: "تخصيص الإعدادات",
                icon: Icons.settings,
                color: Colors.grey,
                onTap: () {
                  // TODO: Implement settings page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("سيتم إضافة هذه الميزة قريباً"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
