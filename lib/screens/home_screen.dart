import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/article_list_item.dart';
import '../widgets/empty_state.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF007BC7),
        elevation: 0,
        title: const Text(
          'PlusNews',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.articles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007BC7)),
              ),
            );
          }

          if (provider.error != null && provider.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Er ging iets mis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadNews(forceRefresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BC7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Opnieuw proberen'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF007BC7),
            onRefresh: () => provider.loadNews(forceRefresh: true),
            child: Column(
              children: [
                if (provider.isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[100],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 16, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Offline modus - Gecachete artikelen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (provider.keywords.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filter: ${provider.keywords.join(", ")}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: provider.articles.isEmpty
                      ? EmptyState(filterText: provider.keywords.join(", "))
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: provider.articles.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey[300],
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            return ArticleListItem(
                              article: provider.articles[index],
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
}