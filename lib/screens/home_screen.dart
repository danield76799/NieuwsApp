import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _searchQuery = '';
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
  }

  void _startAutoRefreshTimer() {
    // Refresh news every 5 minutes while app is open
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
      await provider.loadNews(forceRefresh: true);
      if (mounted) {
        setState(() {
          _lastNewsRefresh = DateTime.now();
        });
      }
    } catch (_) {
      // Silent fail — don't bother user with background refresh errors
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
      // Refresh news if last refresh was more than 5 minutes ago
      if (_lastNewsRefresh == null ||
          DateTime.now().difference(_lastNewsRefresh!) > const Duration(minutes: 5)) {
        _refreshNewsInBackground();
      }
      // Only refresh weather if last fetch was more than 10 minutes ago
      if (_lastWeatherFetch == null ||
          DateTime.now().difference(_lastWeatherFetch!) > const Duration(minutes: 10)) {
        _loadWeather();
      }
    }
  }

  Future<void> _detectLocationAndLoadWeather() async {
    final provider = context.read<NewsProvider>();

    // Detect GPS location if auto-location is enabled
    if (provider.useAutoLocation) {
      await provider.detectLocation();
    }

    await _loadWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load weather once at init, not on every dependency change
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
                  color: Colors.grey[300],
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
            const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        final articles = provider.visibleArticles; // Gebruik visibleArticles i.p.v. articles
        final hasMore = provider.hasMoreArticles;
        final filteredArticles = _searchQuery.isEmpty
            ? articles
            : articles.where((a) =>
                a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                a.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: provider.filterActive ? Colors.amber : Colors.white,
              ),
              onPressed: () {
                provider.toggleFilter(!provider.filterActive);
              },
              tooltip: provider.filterActive ? 'Filter uit' : 'Filter aan',
            ),
            title: const SizedBox.shrink(),
            centerTitle: false,
            actions: [
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
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: app_search.SearchBar(onSearch: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      }),
                    ),
                  );
                },
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
              IconButton(
                icon: Icon(
                  _viewMode == ViewMode.list ? Icons.swipe : Icons.list,
                  color: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    _viewMode = _viewMode == ViewMode.list ? ViewMode.swipe : ViewMode.list;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('swipe_view', _viewMode == ViewMode.swipe);
                },
                tooltip: _viewMode == ViewMode.list ? 'Swipe weergave' : 'Lijst weergave',
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  await _loadWeather();
                },
              ),
              const SizedBox(width: 4),
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
                      if (provider.isLoading && articles.isEmpty)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                      if (provider.error != null && articles.isEmpty)
                        SliverFillRemaining(child: EmptyState(icon: Icons.error_outline, title: 'Oeps!', subtitle: provider.error!, action: ElevatedButton.icon(onPressed: () => provider.loadNews(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('Opnieuw')))),
                      if (!provider.isLoading && provider.error == null && filteredArticles.isEmpty)
                        SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [CircularProgressIndicator(), SizedBox(height: 16), Text('Nieuws laden...')]))),
                      if (filteredArticles.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == 0) {
                                  return ArticleHeroCard(article: filteredArticles[index]);
                                }
                                return ArticleCardV2(article: filteredArticles[index]);
                              },
                              childCount: filteredArticles.length,
                            ),
                          ),
                        ),
                      if (hasMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: provider.loadMoreArticles,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Meer laden'),
                              ),
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
