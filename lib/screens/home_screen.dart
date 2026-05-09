import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../providers/news_provider.dart';
import '../widgets/article_card_v2.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import 'settings_screen.dart';
import 'feeds_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildNewsTab(),
      const BookmarksScreen(),
      const FeedsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Nieuws',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Opgeslagen',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Feeds',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Instellingen',
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'PlusNews',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: ArticleSearchDelegate(provider.articles),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    provider.filterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: provider.filterActive ? Colors.yellow : null,
                  ),
                  onPressed: () {
                    provider.toggleFilter(!provider.filterActive);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.filterActive 
                            ? 'Filter ingeschakeld' 
                            : 'Filter uitgeschakeld'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Filter chips
            if (provider.keywords.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (provider.filterActive)
                        Chip(
                          avatar: const Icon(Icons.filter_list, size: 18),
                          label: Text('Filter: ${provider.keywords.join(", ")}'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => provider.toggleFilter(false),
                        )
                      else
                        ActionChip(
                          avatar: const Icon(Icons.filter_list_off, size: 18),
                          label: Text('${provider.keywords.join(", ")} (uit)'),
                          onPressed: () => provider.toggleFilter(true),
                        ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (provider.isLoading && provider.articles.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.error != null && provider.articles.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Er ging iets mis',
                  subtitle: provider.error ?? 'Onbekende fout',
                  action: ElevatedButton(
                    onPressed: () => provider.loadNews(forceRefresh: true),
                    child: const Text('Opnieuw proberen'),
                  ),
                ),
              )
            else if (provider.articles.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Geen artikelen gevonden',
                  subtitle: 'Probeer andere zoektermen of wacht tot nieuwe artikelen binnenkomen.',
                ),
              )
            else
              // Article list
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = provider.articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ArticleCardV2(article: article),
                      );
                    },
                    childCount: provider.articles.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ArticleSearchDelegate extends SearchDelegate {
  final List articles;

  ArticleSearchDelegate(this.articles);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = articles.where((article) {
      return article.title.toLowerCase().contains(query.toLowerCase()) ||
             article.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ArticleCardV2(article: results[index]);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = articles.where((article) {
      return article.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].title),
          onTap: () {
            query = suggestions[index].title;
            showResults(context);
          },
        );
      },
    );
  }
}
