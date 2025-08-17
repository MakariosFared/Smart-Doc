import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? hintText;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = "كلمة المرور",
    this.validator,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      obscureText: !_isPasswordVisible,
      enabled: widget.enabled,
      validator: widget.validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "يرجى إدخال كلمة المرور";
    }
    if (value.length < 6) {
      return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
    }
    return null;
  }
}
