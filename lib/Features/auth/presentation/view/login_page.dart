import 'package:flutter/material.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/password_field.dart';
import 'widgets/custom_button.dart';
import 'widgets/form_section.dart';
import 'widgets/validation_utils.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Add authentication logic here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to the appropriate home page
        if (widget.role == 'patient') {
          Navigator.pushReplacementNamed(context, '/patient-home');
        } else {
          Navigator.pushReplacementNamed(context, '/doctor-home');
        }
      }
    }
  }

  String _getRoleTitle() {
    return widget.role == 'patient' ? 'مريض' : 'دكتور';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "تسجيل الدخول - $_getRoleTitle",
        backgroundColor: Colors.blue,
      ),
      body: FormSection(
        title: "تسجيل الدخول",
        children: [
          CustomTextField(
            controller: _emailController,
            labelText: "البريد الإلكتروني أو رقم الهاتف",
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: ValidationUtils.validateEmailOrPhone,
          ),
          const FormFieldSpacer(),
          PasswordField(
            controller: _passwordController,
            labelText: "كلمة المرور",
          ),
          const FormFieldSpacer(height: 30),
          CustomButton(
            text: "تسجيل الدخول",
            onPressed: _handleLogin,
            isLoading: _isLoading,
            type: ButtonType.primary,
          ),
          const FormFieldSpacer(),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup', arguments: widget.role);
            },
            child: const Text(
              "ليس لديك حساب؟ إنشاء حساب جديد",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
