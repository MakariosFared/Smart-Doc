import 'package:flutter/material.dart';

class RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSelected;

  const RoleSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 4,
      color: isSelected ? color.withOpacity(0.1) : Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
