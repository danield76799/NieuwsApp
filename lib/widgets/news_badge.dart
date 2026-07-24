import 'package:flutter/material.dart';

/// "Nieuw" badge voor artikelen die minder dan 1 uur oud zijn
class NewsBadge extends StatelessWidget {
  const NewsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NIEUW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
