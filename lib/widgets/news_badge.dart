import 'package:flutter/material.dart';

/// "Nieuw" badge voor artikelen die minder dan 1 uur oud zijn
class NewsBadge extends StatelessWidget {
  const NewsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
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
