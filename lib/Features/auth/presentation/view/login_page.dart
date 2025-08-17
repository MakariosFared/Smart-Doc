import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
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

  @override
  void initState() {
    super.initState();
    // Ensure the form key is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState == null) {
        print('Warning: Form not properly initialized');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    try {
      final formState = _formKey.currentState;
      if (formState != null && formState.validate()) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        if (email.isNotEmpty && password.isNotEmpty) {
          context.read<AuthCubit>().login(email, password);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى ملء جميع الحقول المطلوبة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handleLogin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء معالجة الطلب'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleTitle() {
    return widget.role == 'patient' ? 'مريض' : 'دكتور';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "تسجيل الدخول - ${_getRoleTitle()}",
        backgroundColor: Colors.blue,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Navigate based on user role from Firebase
            if (state.user.isPatient) {
              Navigator.pushReplacementNamed(context, '/patient-home');
            } else if (state.user.isDoctor) {
              Navigator.pushReplacementNamed(context, '/doctor-home');
            }
          } else if (state is AuthFailure) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: FormSection(
              title: "تسجيل الدخول",
              children: [
                CustomTextField(
                  controller: _emailController,
                  labelText: "البريد الإلكتروني",
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
                  onPressed: state is AuthLoading ? null : _handleLogin,
                  isLoading: state is AuthLoading,
                  type: ButtonType.primary,
                ),
                const FormFieldSpacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/signup',
                      arguments: widget.role,
                    );
                  },
                  child: const Text(
                    "ليس لديك حساب؟ إنشاء حساب جديد",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
