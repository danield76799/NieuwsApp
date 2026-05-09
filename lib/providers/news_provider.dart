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

  NewsProvider(this._repository) {
    _loadKeywords();
  }

  List<Article> get articles => _filteredArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get keywords => _keywords;
  bool get isOffline => _isOffline;

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

  Future<void> _loadKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('keywords') ?? '';
    if (saved.isNotEmpty) {
      _keywords = saved.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    }
    notifyListeners();
  }

  Future<void> setKeywords(String keywordString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('keywords', keywordString);

    _keywords = keywordString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    _applyFilter();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}