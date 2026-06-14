import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';
import '../services/location_service.dart';
import '../services/article_cache_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository;

  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  bool _isLoading = false;
  String? _error;
  List<String> _keywords = [];
  bool _filterActive = false;
  String _weatherCity = 'Amsterdam';
  bool _useAutoLocation = true;
  String? _currentPosition;

  NewsProvider(this._repository) {
    _loadSavedData();
  }

  List<Article> get articles => _filterActive ? _filteredArticles : _articles;

  // Pagination
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  List<Article> get visibleArticles => articles.take(_visibleCount).toList();
  bool get hasMoreArticles => articles.length > _visibleCount;

  void loadMoreArticles() {
    _visibleCount += _pageSize;
    notifyListeners();
  }

  void resetPagination() {
    _visibleCount = _pageSize;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get keywords => _keywords;
  bool get filterActive => _filterActive;
  String get weatherCity => _weatherCity;
  bool get useAutoLocation => _useAutoLocation;

  Future<void> _loadSavedData() async {
    // Load settings and cached articles in parallel
    final prefs = await SharedPreferences.getInstance();
    
    // Load keywords
    final savedKeywords = prefs.getString('keywords') ?? '';
    if (savedKeywords.isNotEmpty) {
      _keywords = savedKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    }
    _filterActive = prefs.getBool('filter_active') ?? false;
    _weatherCity = prefs.getString('weather_city') ?? 'Amsterdam';
    _useAutoLocation = prefs.getBool('auto_location') ?? true;
    _currentPosition = prefs.getString('current_position');

    // Direct cached articles laden - geen isValid check (sneller)
    final cachedArticles = await ArticleCacheService.getCachedArticles();
    if (cachedArticles.isNotEmpty) {
      _articles = cachedArticles;
      _applyFilter();
      notifyListeners();
    }
    
    // Altijd background refresh voor verse data
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    try {
      final articles = await _repository.fetchNews();
      if (articles.isNotEmpty) {
        _articles = articles.take(50).toList();
        _articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
        _applyFilter();
        resetPagination();
        notifyListeners();

        // Cache the article list (fast, no HTTP)
        ArticleCacheService.cacheArticles(_articles);
        
        // Cache all article content in background (parallel, non-blocking)
        ArticleCacheService.cacheArticlesContent(_articles);
      }
    } catch (e) {
      // Silent fail - don't show error for background refresh
      print('Background refresh failed: $e');
    }
  }

  Future<void> loadNews({bool forceRefresh = false}) async {
    // Direct cached tonen, dan background refresh
    if (!forceRefresh) {
      final cachedArticles = await ArticleCacheService.getCachedArticles();
      if (cachedArticles.isNotEmpty) {
        _articles = cachedArticles;
        _applyFilter();
        resetPagination();
        notifyListeners();
        // Background refresh voor verse data
        _refreshInBackground();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final articles = await _repository.fetchNews();
      _articles = articles.take(50).toList();
      _articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      _applyFilter();
      resetPagination();
      ArticleCacheService.cacheArticles(_articles);
    } catch (e) {
      _error = e.toString();
      final cachedArticles = await ArticleCacheService.getCachedArticles();
      if (cachedArticles.isNotEmpty) {
        _articles = cachedArticles;
        _applyFilter();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    if (_keywords.isEmpty || !_filterActive) {
      _filteredArticles = [];
      return;
    }
    _filteredArticles = _articles.where((article) {
      final text = '${article.title} ${article.description}'.toLowerCase();
      return _keywords.any((keyword) => text.contains(keyword.toLowerCase()));
    }).toList();
  }

  Future<void> setKeywords(String keywordString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('keywords', keywordString);

    _keywords = keywordString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    _applyFilter();
    notifyListeners();
  }

  Future<void> toggleFilter(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_active', active);

    _filterActive = active;
    _applyFilter();
    notifyListeners();
  }

  Future<void> clearKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('keywords');
    await prefs.setBool('filter_active', false);

    _keywords = [];
    _filterActive = false;
    _applyFilter();
    notifyListeners();
  }

  Future<void> setWeatherCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_city', city);
    _weatherCity = city;
    notifyListeners();
  }

  Future<void> detectLocation() async {
    if (!_useAutoLocation) return;

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      _currentPosition = '${position.latitude},${position.longitude}';
      
      // Probeer stad naam te krijgen
      final cityName = await LocationService.getCityFromPosition(position);
      if (cityName != null) {
        _weatherCity = cityName;
      }
      
      // Save position
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_position', _currentPosition!);
      if (cityName != null) {
        await prefs.setString('weather_city', cityName);
      }
    }
  }

  Future<void> setUseAutoLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_location', value);

    _useAutoLocation = value;
    if (value) {
      await detectLocation();
    } else {
      _currentPosition = null;
      await prefs.remove('current_position');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}
