import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, danger, success }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isFullWidth;
  final double? height;
  final double? width;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isFullWidth = true,
    this.height = 50,
    this.width,
    this.icon,
    this.isLoading = false,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return Colors.blue;
      case ButtonType.secondary:
        return Colors.grey;
      case ButtonType.danger:
        return Colors.red;
      case ButtonType.success:
        return Colors.green;
    }
  }

  Color _getForegroundColor() {
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(text, style: const TextStyle(fontSize: 18)),
                ],
              ),
      ),
    );
  }
}
