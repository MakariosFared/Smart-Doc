import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconPressed;
  final TextDirection? textDirection;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSuffixIconPressed,
    this.textDirection,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon != null
            ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixIconPressed)
            : null,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: textDirection,
      enabled: enabled,
    );
  }
}
