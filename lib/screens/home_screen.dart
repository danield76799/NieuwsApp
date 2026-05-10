import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../services/weather_service.dart';
import '../widgets/article_card_v2.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart' as app_search;
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _detectLocationAndLoadWeather();
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
    // Only load weather, don't detect location here to avoid rebuild issues
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final provider = context.read<NewsProvider>();
    final weather = await WeatherService.getWeatherForCity(provider.weatherCity);
    if (mounted) {
      setState(() {
        _weatherData = weather;
      });
    }
  }

  void _showWeatherPopup() {
    if (_weatherData == null) return;
    
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
                return Column(children: [
                  Text(dayName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
        final articles = provider.articles;
        final allArticles = provider.articles;
        final filteredArticles = _searchQuery.isEmpty
            ? articles
            : articles.where((a) =>
                a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                a.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Scaffold(
          body: RefreshIndicator(
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
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: true,
                  expandedHeight: 120,
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
                    if (_weatherData != null)
                      InkWell(
                        onTap: _showWeatherPopup,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.wb_sunny, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('${_weatherData!['temp']}°', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {
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
                    }),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      await _loadWeather();
                    }),
                    const SizedBox(width: 8),
                  ],
                ),

                // Filter only info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: Icon(provider.filterActive ? Icons.visibility : Icons.visibility_off, size: 18, color: provider.filterActive ? Colors.green : Colors.grey),
                          label: Text(
                            provider.filterActive ? 'Filter: AAN' : 'Filter: UIT',
                            style: TextStyle(fontSize: 12, color: provider.filterActive ? Colors.green : Colors.grey),
                          ),
                          onPressed: () => provider.toggleFilter(!provider.filterActive),
                          backgroundColor: provider.filterActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading state
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
