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
  bool _initialized = false;

  NewsProvider(this._repository) {
    _init();
  }

  List<Article> get articles => _filteredArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get keywords => _keywords;
  bool get isOffline => _isOffline;
  bool get filterEnabled => _keywords.isNotEmpty;

  Future<void> _init() async {
    await _loadKeywords();
    _initialized = true;
    loadNews();
  }

  Future<void> loadNews({bool forceRefresh = false}) async {
    if (!_initialized) return;
    
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

  Future<void> _loadKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('keywords') ?? '';
      if (saved.isNotEmpty) {
        _keywords = saved.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
        _applyFilter();
      }
    } catch (e) {
      print('Error loading keywords: $e');
    }
    notifyListeners();
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

  Future<void> clearKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('keywords');
      _keywords = [];
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