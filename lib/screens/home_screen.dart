import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/article_card_v2.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart' as app_search;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        final articles = provider.articles;
        final filteredArticles = _searchQuery.isEmpty
            ? articles
            : articles.where((a) =>
                a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                a.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => provider.loadNews(forceRefresh: true),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            displacement: 40,
            strokeWidth: 3,
            child: CustomScrollView(
              slivers: [
                // SliverAppBar
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: true,
                  expandedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'PlusNews',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    // Search icon
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: app_search.SearchBar(
                              onSearch: (query) {
                                setState(() {
                                  _searchQuery = query;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    // Filter toggle
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: provider.filterActive ? Colors.amber : null,
                      ),
                      onPressed: () => provider.toggleFilter(!provider.filterActive),
                      tooltip: provider.filterActive ? 'Filter uit' : 'Filter aan',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Filter chips
                if (provider.keywords.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            avatar: Icon(
                              provider.filterActive ? Icons.visibility : Icons.visibility_off,
                              size: 18,
                              color: provider.filterActive ? Colors.green : Colors.grey,
                            ),
                            label: Text(
                              provider.filterActive ? 'Filter: AAN' : 'Filter: UIT',
                              style: TextStyle(
                                fontSize: 12,
                                color: provider.filterActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            onPressed: () => provider.toggleFilter(!provider.filterActive),
                            backgroundColor: provider.filterActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                          ),
                          ...provider.keywords.map((keyword) => Chip(
                            label: Text(
                              keyword,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              final newKeywords = provider.keywords.where((k) => k != keyword).toList();
                              provider.setKeywords(newKeywords.join(', '));
                            },
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          )),
                        ],
                      ),
                    ),
                  ),

                // Loading state
                if (provider.isLoading && articles.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Nieuws laden...'),
                        ],
                      ),
                    ),
                  ),

                // Error state
                if (provider.error != null && articles.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Oeps!',
                      subtitle: provider.error!,
                      action: ElevatedButton.icon(
                        onPressed: () => provider.loadNews(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Opnieuw proberen'),
                      ),
                    ),
                  ),

                // Empty state
                if (!provider.isLoading && provider.error == null && filteredArticles.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.article_outlined,
                      title: _searchQuery.isNotEmpty ? 'Geen resultaten' : 'Geen artikelen',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Probeer een andere zoekterm'
                          : 'Trek naar beneden om te vernieuwen',
                    ),
                  ),

                // Articles list
                if (filteredArticles.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final article = filteredArticles[index];
                          return ArticleCardV2(article: article);
                        },
                        childCount: filteredArticles.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}