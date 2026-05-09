import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../services/bookmark_service.dart';
import '../widgets/article_card.dart';
import 'settings_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _bookmarkService = BookmarkService();
  int _bookmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBookmarkCount();
  }

  Future<void> _loadBookmarkCount() async {
    await _bookmarkService.initialize();
    setState(() {
      _bookmarkCount = _bookmarkService.bookmarkCount;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nieuws'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/bookmarks');
                  _loadBookmarkCount();
                },
              ),
              if (_bookmarkCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_bookmarkCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          // DEBUG INFO
          debugPrint('DEBUG: isLoading=${provider.isLoading}, articles=${provider.articles.length}, error=${provider.error}');
          
          if (provider.isLoading && provider.articles.isEmpty) {
            return _buildLoadingWidget();
          }

          if (provider.error != null && provider.articles.isEmpty) {
            return _buildErrorWidget(provider);
          }

          return RefreshIndicator(
            onRefresh: provider.loadNews,
            color: const Color(0xFF1E88E5),
            child: Column(
              children: [
                if (provider.hasFilters)
                  _buildFilterChips(provider),
                
                // DEBUG BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber[100],
                  child: Text(
                    'DEBUG: ${provider.articles.length} artikelen | _articles=${provider.allArticles.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Expanded(
                  child: provider.articles.isEmpty
                      ? _buildEmptyWidget()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.articles.length,
                          itemBuilder: (context, index) {
                            final article = provider.articles[index];
                            return ArticleCard(
                              article: article,
                              showBookmarkButton: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF1E88E5),
          ),
          SizedBox(height: 16),
          Text(
            'Nieuws laden...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(NewsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.loadNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Geen artikelen gevonden',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pas je filters aan of zoek op andere termen',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(NewsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (provider.selectedCategory != 'all')
            Chip(
              label: Text(provider.selectedCategory),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => provider.setCategory('all'),
              backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
              side: BorderSide(color: const Color(0xFF1E88E5).withOpacity(0.3)),
            ),
          ...provider.keywords.map((keyword) => Chip(
            label: Text(keyword),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => provider.removeKeyword(keyword),
            backgroundColor: Colors.orange.withOpacity(0.1),
            side: BorderSide(color: Colors.orange.withOpacity(0.3)),
          )),
          ActionChip(
            label: const Text('Wis filters'),
            onPressed: provider.clearFilters,
            avator: const Icon(Icons.clear_all, size: 18),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoeken'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Zoekterm...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              context.read<NewsProvider>().searchNews(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_searchController.text.isNotEmpty) {
                context.read<NewsProvider>().searchNews(_searchController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Zoeken'),
          ),
        ],
      ),
    );
  }
}
