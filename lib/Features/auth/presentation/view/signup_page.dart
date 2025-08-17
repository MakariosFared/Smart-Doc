import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Add signup logic here
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
      appBar: CommonAppBar(title: "إنشاء حساب - $_getRoleTitle"),
      body: SingleChildScrollView(
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
              const FormFieldSpacer(),
              PasswordField(
                controller: _confirmPasswordController,
                labelText: "تأكيد كلمة المرور",
                validator: (value) => ValidationUtils.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const FormFieldSpacer(height: 30),
              CustomButton(
                text: "إنشاء الحساب",
                onPressed: _handleSignup,
                isLoading: _isLoading,
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
      ),
    );
  }
}
