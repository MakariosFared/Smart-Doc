import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/models/app_user.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/password_field.dart';
import 'widgets/custom_button.dart';
import 'widgets/form_section.dart';
import 'widgets/validation_utils.dart';

class SignupPage extends StatefulWidget {
  final String role;

  const SignupPage({super.key, required this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    try {
      final formState = _formKey.currentState;
      if (formState != null && formState.validate()) {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;

        if (name.isNotEmpty &&
            email.isNotEmpty &&
            password.isNotEmpty &&
            confirmPassword.isNotEmpty) {
          final UserRole userRole = widget.role == 'patient'
              ? UserRole.patient
              : UserRole.doctor;

          context.read<AuthCubit>().signup(name, email, password, userRole);
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
      print('Error in _handleSignup: $e');
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
        title: "إنشاء حساب - ${_getRoleTitle()}",
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
          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: FormSection(
                title: "إنشاء حساب جديد",
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: "الاسم الكامل",
                    prefixIcon: Icons.person,
                    textDirection: TextDirection.rtl,
                    validator: ValidationUtils.validateName,
                  ),
                  const FormFieldSpacer(),
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
                  const FormFieldSpacer(),
                  PasswordField(
                    controller: _confirmPasswordController,
                    labelText: "تأكيد كلمة المرور",
                    validator: (value) =>
                        ValidationUtils.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                  ),
                  const FormFieldSpacer(height: 30),
                  CustomButton(
                    text: "إنشاء الحساب",
                    onPressed: state is AuthLoading ? null : _handleSignup,
                    isLoading: state is AuthLoading,
                    type: ButtonType.success,
                  ),
                  const FormFieldSpacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "لديك حساب بالفعل؟ تسجيل الدخول",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
