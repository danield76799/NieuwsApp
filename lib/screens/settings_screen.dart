import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Instellingen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Keyword Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voeg keywords toe om alleen nieuws te zien dat deze woorden bevat.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Add keyword input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keywordController,
                        decoration: InputDecoration(
                          hintText: 'Bijv. AI, Economie, Sport...',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E88E5),
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: (value) => _addKeyword(provider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _addKeyword(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Toevoegen'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Suggested keywords
                Text(
                  'Suggesties',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'AI',
                    'Economie',
                    'Sport',
                    'Politiek',
                    'Tech',
                    'Gezondheid',
                    'Klimaat',
                    'Onderwijs',
                  ].map((keyword) => ActionChip(
                    label: Text(keyword),
                    onPressed: () {
                      _keywordController.text = keyword;
                      _addKeyword(provider);
                    },
                    backgroundColor: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    side: BorderSide(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 32),

                // Active keywords
                if (provider.keywords.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actieve filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton(
                        onPressed: provider.clearFilters,
                        child: const Text(
                          'Wis alle',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...provider.keywords.map((keyword) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tag,
                          color: Color(0xFF1E88E5),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        keyword,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => provider.removeKeyword(keyword),
                      ),
                    ),
                  )),
                ],

                // Categories
                const SizedBox(height: 32),
                Text(
                  'Categorie',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(NewsProvider provider) {
    final categories = [
      {'id': 'all', 'name': 'Alles', 'icon': Icons.all_inclusive},
      {'id': 'general', 'name': 'Algemeen', 'icon': Icons.article},
      {'id': 'business', 'name': 'Economie', 'icon': Icons.business},
      {'id': 'technology', 'name': 'Tech', 'icon': Icons.computer},
      {'id': 'sports', 'name': 'Sport', 'icon': Icons.sports},
      {'id': 'health', 'name': 'Gezondheid', 'icon': Icons.health_and_safety},
      {'id': 'science', 'name': 'Wetenschap', 'icon': Icons.science},
      {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = provider.selectedCategory == cat['id'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cat['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF1E88E5),
              ),
              const SizedBox(width: 6),
              Text(cat['name'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => provider.setCategory(cat['id'] as String),
          selectedColor: const Color(0xFF1E88E5),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  void _addKeyword(NewsProvider provider) {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty) {
      provider.addKeyword(keyword);
      _keywordController.clear();
    }
  }
}