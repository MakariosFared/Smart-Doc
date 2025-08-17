import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';
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
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccess) {
          // Navigate back to role selection page on logout
          Navigator.pushReplacementNamed(context, '/');
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: title,
          backgroundColor: themeColor,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  40, // 40 for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Icon(icon, size: 80, color: themeColor),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "هذه صفحة مؤقتة - سيتم إضافة الميزات لاحقاً",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (additionalWidgets != null) ...[
                    const SizedBox(height: 24),
                    ...additionalWidgets!,
                  ],
                  const Spacer(),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "تسجيل الخروج",
                    onPressed:
                        onLogout ??
                        () {
                          context.read<AuthCubit>().logout();
                        },
                    type: ButtonType.danger,
                    icon: Icons.logout,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
