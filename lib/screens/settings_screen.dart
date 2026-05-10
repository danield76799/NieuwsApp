import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keywordsController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<NewsProvider>();
    _keywordsController.text = provider.keywords.join(', ');
    _cityController.text = provider.weatherCity;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Instellingen'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Weather City
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weer stad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          hintText: 'Bijv. Amsterdam, Almere',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          provider.setWeatherCity(_cityController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stad opgeslagen!')),
                          );
                        },
                        child: const Text('Opslaan'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Keywords
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter keywords',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keywordsController,
                        decoration: const InputDecoration(
                          hintText: 'Bijv. Trump, Tech, Sport',
                          border: OutlineInputBorder(),
                          helperText: 'Scheid met komma\'s',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              provider.setKeywords(_keywordsController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Keywords opgeslagen!')),
                              );
                            },
                            child: const Text('Opslaan'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              provider.clearKeywords();
                              _keywordsController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Keywords gewist!')),
                              );
                            },
                            child: const Text('Wissen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Current keywords
              if (provider.keywords.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Huidige keywords:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: provider.keywords.map((keyword) => Chip(
                            label: Text(keyword),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}