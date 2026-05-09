import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';

/// Provider voor niewws state management
class NewsProvider extends ChangeNotifier {
  final _newsApi = NewsApiService();
  late Box<dynamic> _settingsBox;
  
  List<Article> _articles = [];
  List<String> _keywords = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';

  // Getters
  List<Article> get articles => _articles;
  List<String> get keywords => _keywords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  bool get hasFilters => _keywords.isNotEmpty || _selectedCategory != 'all';

  NewsProvider() {
    _init();
  }

  Future<void> _init() async {
    _settingsBox = await Hive.openBox('news_settings');
    _loadKeywords();
    await loadNews();
  }

  /// Laad keywords uit lokale opslag
  void _loadKeywords() {
    final savedKeywords = _settingsBox.get('keywords');
    if (savedKeywords != null) {
      _keywords = List<String>.from(savedKeywords);
    }
  }

  /// Haal nieuws op
  Future<void> loadNews() async {
    _setLoading(true);
    _error = null;

    try {
      final articles = await _newsApi.getTopHeadlines(
        country: 'nl',
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      
      _articles = articles;
      _setLoading(false);
    } catch (e) {
      _error = 'Kon nieuws niet laden: $e';
      _setLoading(false);
    }
  }

  /// Zoek nieuws op keywords
  Future<void> searchNews(String query) async {
    if (query.isEmpty) {
      await loadNews();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final articles = await _newsApi.searchNews(query: query);
      _articles = articles;
      _setLoading(false);
    } catch (e) {
      _error = 'Zoeken mislukt: $e';
      _setLoading(false);
    }
  }

  /// Voeg keyword filter toe
  Future<void> addKeyword(String keyword) async {
    if (keyword.isEmpty || _keywords.contains(keyword)) return;
    
    _keywords.add(keyword.toLowerCase());
    await _settingsBox.put('keywords', _keywords);
    notifyListeners();
  }

  /// Verwijder keyword filter
  Future<void> removeKeyword(String keyword) async {
    _keywords.remove(keyword.toLowerCase());
    await _settingsBox.put('keywords', _keywords);
    notifyListeners();
  }

  /// Wijzig categorie
  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    await loadNews();
  }

  /// Verwijder alle filters
  void clearFilters() {
    _keywords.clear();
    _settingsBox.put('keywords', []);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
