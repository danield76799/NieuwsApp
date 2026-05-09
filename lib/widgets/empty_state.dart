import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String? filterText;

  const EmptyState({super.key, this.filterText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              filterText != null && filterText!.isNotEmpty
                  ? 'Geen artikelen gevonden voor: "$filterText"'
                  : 'Geen artikelen beschikbaar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filterText != null
                  ? 'Probeer andere keywords of verwijder het filter.'
                  : 'Trek omlaag om te verversen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}