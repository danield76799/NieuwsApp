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

  Future<void> _loadKeywordsAndNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved keywords
      final savedKeywords = prefs.getString('keywords') ?? '';
      if (savedKeywords.isNotEmpty) {
        _keywords = savedKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
      }
      
      // Load filter active state
      _filterActive = prefs.getBool('filter_active') ?? false;
    } catch (e) {
      print('Error loading keywords: $e');
    }
    
    await loadNews();
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    _filteredArticles = _repository.filterByKeywords(_articles, _keywords);
  }

  Future<void> setKeywords(String keywordString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('keywords', keywordString);

      _keywords = keywordString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
      _applyFilter();
      notifyListeners();
    } catch (e) {
      print('Error saving keywords: $e');
    }
  }

  Future<void> toggleFilter(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('filter_active', active);
      
      _filterActive = active;
      notifyListeners();
    } catch (e) {
      print('Error toggling filter: $e');
    }
  }

  Future<void> clearKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('keywords');
      await prefs.setBool('filter_active', false);
      
      _keywords = [];
      _filterActive = false;
      _applyFilter();
      notifyListeners();
    } catch (e) {
      print('Error clearing keywords: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
