import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository;

  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  bool _isLoading = false;
  String? _error;
  List<String> _keywords = [];
  bool _isOffline = false;
  bool _filterActive = false;
  bool _initialized = false;

  NewsProvider(this._repository) {
    _loadKeywordsAndNews();
  }

  List<Article> get articles => _filterActive ? _filteredArticles : _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get keywords => _keywords;
  bool get isOffline => _isOffline;
  bool get filterActive => _filterActive;
  bool get filterEnabled => _keywords.isNotEmpty;
  bool get initialized => _initialized;

  Future<void> _loadKeywordsAndNews() async {
    print('NewsProvider: Loading keywords and news...');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved keywords
      final savedKeywords = prefs.getString('keywords') ?? '';
      print('NewsProvider: Saved keywords: "$savedKeywords"');
      if (savedKeywords.isNotEmpty) {
        _keywords = savedKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
        print('NewsProvider: Loaded keywords: $_keywords');
      } else {
        _keywords = [];
        print('NewsProvider: No keywords found');
      }
      
      // Load filter active state
      _filterActive = prefs.getBool('filter_active') ?? false;
      print('NewsProvider: Filter active: $_filterActive');
    } catch (e) {
      print('NewsProvider: Error loading keywords: $e');
    }
    
    await loadNews();
    _initialized = true;
    notifyListeners();
  }

  Future<void> loadNews({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final articles = await _repository.fetchNews();
      _articles = articles;
      _isOffline = false;
      _applyFilter();
      print('NewsProvider: Loaded ${articles.length} articles');
    } catch (e) {
      _error = e.toString();
      print('NewsProvider: Error loading news: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    if (_keywords.isEmpty) {
      _filteredArticles = [];
      return;
    }
    _filteredArticles = _repository.filterByKeywords(_articles, _keywords);
    print('NewsProvider: Applied filter, ${_filteredArticles.length} articles match');
  }

  Future<void> setKeywords(String keywordString) async {
    print('NewsProvider: Setting keywords: "$keywordString"');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save to SharedPreferences
      await prefs.setString('keywords', keywordString);
      print('NewsProvider: Saved keywords to SharedPreferences');

      // Update local state
      _keywords = keywordString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
      
      // Apply filter
      _applyFilter();
      
      // Notify listeners
      notifyListeners();
      print('NewsProvider: Keywords updated: $_keywords');
    } catch (e) {
      print('NewsProvider: Error saving keywords: $e');
    }
  }

  Future<void> toggleFilter(bool active) async {
    print('NewsProvider: Toggling filter to: $active');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('filter_active', active);
      
      _filterActive = active;
      notifyListeners();
      print('NewsProvider: Filter toggled to: $_filterActive');
    } catch (e) {
      print('NewsProvider: Error toggling filter: $e');
    }
  }

  Future<void> clearKeywords() async {
    print('NewsProvider: Clearing keywords');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('keywords');
      await prefs.setBool('filter_active', false);
      
      _keywords = [];
      _filterActive = false;
      _applyFilter();
      notifyListeners();
      print('NewsProvider: Keywords cleared');
    } catch (e) {
      print('NewsProvider: Error clearing keywords: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
