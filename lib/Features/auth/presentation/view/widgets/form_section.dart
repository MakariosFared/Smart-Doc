import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(20.0),
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding!,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...children,
        ],
      ),
    );
  }
}

class FormFieldSpacer extends StatelessWidget {
  final double height;

  const FormFieldSpacer({super.key, this.height = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
