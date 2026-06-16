import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final Function() onCancel;

  const CustomSearchBar({super.key, required this.onSearch, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Zoeken...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ),
        onSubmitted: onSearch,
      ),
    );
  }
}