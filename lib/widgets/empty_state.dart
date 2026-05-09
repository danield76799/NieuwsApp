import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final String? filterText;

  const EmptyState({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.action,
    this.filterText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 64, color: Colors.grey[400]),
            if (icon != null) const SizedBox(height: 16),
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            if (title != null) const SizedBox(height: 8),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            if (filterText != null && filterText!.isNotEmpty)
              Text(
                'Geen artikelen gevonden voor: "$filterText"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}