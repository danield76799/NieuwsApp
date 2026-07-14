import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feed_service.dart';
import '../providers/news_provider.dart';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  List<Map<String, String>> _feeds = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    final feeds = await FeedService.getFeeds();
    setState(() {
      _feeds = feeds;
      _isLoading = false;
    });
  }

  Future<void> _addFeed() async {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul naam en URL in')),
      );
      return;
    }

    await FeedService.addFeed(_nameController.text.trim(), _urlController.text.trim());
    _nameController.clear();
    _urlController.clear();
    await _loadFeeds();

    // Reload news in provider
    if (!mounted) return;
    final provider = context.read<NewsProvider>();
    await provider.loadNews(forceRefresh: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feed toegevoegd - artikelen herladen...')),
    );
  }

  Future<void> _removeFeed(String url) async {
    await FeedService.removeFeed(url);
    await _loadFeeds();

    // Reload news in provider
    if (!mounted) return;
    final provider = context.read<NewsProvider>();
    await provider.loadNews(forceRefresh: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feed verwijderd - artikelen herladen...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS Feeds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add new feed
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nieuwe feed toevoegen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Naam (bijv. Nu.nl)',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'RSS URL (bijv. https://nu.nl/rss)',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addFeed,
                            child: const Text('Toevoegen'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Actieve feeds',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feed list
                  ..._feeds.map((feed) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(feed['name'] ?? 'Onbekend'),
                        subtitle: Text(
                          feed['url'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () => _removeFeed(feed['url']!),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
