import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../providers/news_provider.dart';
import '../services/weather_service.dart';
import '../widgets/article_card_v2.dart';
import '../widgets/swipe_card_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart' as app_search;
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

enum ViewMode { list, swipe }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _weatherData;
  DateTime? _lastWeatherFetch;
  DateTime? _lastNewsRefresh;
  ViewMode _viewMode = ViewMode.list;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectLocationAndLoadWeather();
    _loadViewMode();
    _startAutoRefreshTimer();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadThumbnailsFromProvider();
    });
  }

  Future<void> _preloadThumbnailsFromProvider() async {
    if (!mounted) return;
    final provider = context.read<NewsProvider>();
    final articles = provider.articles;
    if (articles.isNotEmpty) {
      await _preloadThumbnails(articles);
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshNewsInBackground();
    });
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isSwipe = prefs.getBool('swipe_view') ?? false;
    setState(() {
      _viewMode = isSwipe ? ViewMode.swipe : ViewMode.list;
    });
  }

  Future<void> _refreshNewsInBackground() async {
    final provider = context.read<NewsProvider>();
    try {
      await provider.loadNews();
      if (mounted) {
        setState(() {
          _lastNewsRefresh = DateTime.now();
        });
        
        final articles = provider.articles;
        if (articles.isNotEmpty) {
          _preloadThumbnails(articles);
        }
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _preloadThumbnails(List<Article> articles) async {
    int preloaded = 0;
    const maxPreload = 7;
    for (final article in articles) {
      if (preloaded >= maxPreload) break;
      
      final url = article.thumbnailUrl ?? article.imageUrl;
      if (url != null && url.isNotEmpty && mounted) {
        try {
          await precacheImage(
            NetworkImage(url, headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            }),
            context,
          );
          preloaded++;
        } catch (_) {
          // Silent fail
        }
      }
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastNewsRefresh == null ||
          DateTime.now().difference(_lastNewsRefresh!) > const Duration(minutes: 5)) {
        _refreshNewsInBackground();
      }
      if (_lastWeatherFetch == null ||
          DateTime.now().difference(_lastWeatherFetch!) > const Duration(minutes: 10)) {
        _loadWeather();
      }
    }
  }

  Future<void> _detectLocationAndLoadWeather() async {
    final provider = context.read<NewsProvider>();

    if (provider.useAutoLocation) {
      await provider.detectLocation();
    }

    await _loadWeather();
  }

  Future<void> _loadWeather() async {
    final provider = context.read<NewsProvider>();
    final weather = await WeatherService.getWeatherForCity(provider.weatherCity);
    if (mounted && weather != null) {
      setState(() {
        _weatherData = weather;
        _lastWeatherFetch = DateTime.now();
      });
    }
  }

  void _showWeatherPopup() {
    if (_weatherData == null) return;

    final currentIcon = WeatherService.getWeatherIcon(_weatherData!['description'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Weer in ${_weatherData!['location'] ?? 'Amsterdam'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(currentIcon, size: 48, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  '${_weatherData!['temp']}°',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_weatherData!['description'], style: const TextStyle(fontSize: 18)),
                    Text('Voelt als ${_weatherData!['feelsLike']}°', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Voorspelling', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: (_weatherData!['forecast'] as List).map((day) {
                final date = DateTime.parse(day['date']);
                final dayName = ['Zo', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za'][date.weekday % 7];
                final dayIcon = day['icon'] as IconData? ?? Icons.wb_sunny;
                return Column(children: [
                  Text(dayName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Icon(dayIcon, size: 24, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text('${day['maxTemp']}°', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${day['minTemp']}°', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ]);
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatLastRefresh(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'zojuist';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m geleden';
    if (diff.inHours < 24) return '${diff.inHours}u geleden';
    return '${dt.day}-${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        final filteredArticles = provider.visibleArticles;
        final hasMore = provider.hasMoreArticles;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Nieuws'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      final provider = context.read<NewsProvider>();
                      return Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: app_search.SearchBar(onSearch: (query) {
                          provider.updateSearchQuery(query);
                        }),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: provider.filterActive ? Colors.amber : Colors.white,
                ),
                onPressed: () {
                  provider.toggleFilter(!provider.filterActive);
                },
              ),
              if (_weatherData != null)
                TextButton.icon(
                  onPressed: _showWeatherPopup,
                  icon: Icon(
                    WeatherService.getWeatherIcon(_weatherData!['description'] ?? ''),
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    '${_weatherData!['temp']}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bookmark, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                  );
                },
              ),
            ],
          ),
          body: _viewMode == ViewMode.swipe
              ? Column(
                  children: [
                    Expanded(
                      child: SwipeCardView(
                        articles: filteredArticles,
                        onRefresh: () async {
                          await provider.loadNews(forceRefresh: true);
                          await _loadWeather();
                        },
                      ),
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: provider.loadMoreArticles,
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Meer laden'),
                          ),
                        ),
                      ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadNews(forceRefresh: true);
                    await _loadWeather();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  displacement: 40,
                  strokeWidth: 3,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Row(
                            children: [
                              ActionChip(
                                avatar: Icon(
                                  provider.filterActive ? Icons.visibility : Icons.visibility_off,
                                  size: 18,
                                  color: provider.filterActive ? Colors.green : Colors.grey[400],
                                ),
                                label: Text(
                                  provider.filterActive ? 'Filter: AAN' : 'Filter: UIT',
                                  style: TextStyle(fontSize: 12, color: provider.filterActive ? Colors.green : Colors.grey[400]),
                                ),
                                onPressed: () => provider.toggleFilter(!provider.filterActive),
                                backgroundColor: provider.filterActive ? Colors.green.withOpacity(0.1) : Colors.grey[700]!.withOpacity(0.2),
                                side: BorderSide(color: provider.filterActive ? Colors.green.withOpacity(0.3) : Colors.grey[500]!.withOpacity(0.3), width: 1),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              if (provider.filterActive && provider.keywords.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text('${provider.keywords.length} actief', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (provider.isLoading && filteredArticles.isEmpty)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                      if (provider.error != null && filteredArticles.isEmpty)
                        SliverFillRemaining(child: EmptyState(icon: Icons.error_outline, title: 'Oeps!', subtitle: provider.error!, action: ElevatedButton.icon(onPressed: () => provider.loadNews(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('Opnieuw')))),
                      if (!provider.isLoading && provider.error == null && filteredArticles.isEmpty)
                        const SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Nieuws laden...')]))),
                      if (filteredArticles.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // Render all article cards without truncation.
                                return RepaintBoundary(
                                  child: index == 0
                                      ? ArticleHeroCard(article: filteredArticles[index])
                                      : ArticleCardV2(article: filteredArticles[index]),
                                );
                              },
                              childCount: filteredArticles.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'NieuwsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      if (_lastNewsRefresh != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Laatst vernieuwd: ${_formatLastRefresh(_lastNewsRefresh!)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Favorieten'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarksScreen())),
                ),
                ListTile(
                  leading: Icon(_viewMode == ViewMode.list ? Icons.swipe : Icons.list),
                  title: Text(_viewMode == ViewMode.list ? 'Swipe weergave' : 'Lijstweergave'),
                  onTap: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    setState(() {
                      _viewMode = _viewMode == ViewMode.list ? ViewMode.swipe : ViewMode.list;
                    });
                    await prefs.setBool('swipe_view', _viewMode == ViewMode.swipe);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Instellingen'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}