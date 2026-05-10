import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';
import '../services/location_service.dart';

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
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get keywords => _keywords;
  bool get filterActive => _filterActive;
  String get weatherCity => _currentPosition ?? _weatherCity;
  bool get useAutoLocation => _useAutoLocation;

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load keywords
    final savedKeywords = prefs.getString('keywords') ?? '';
    if (savedKeywords.isNotEmpty) {
      _keywords = savedKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    }
    
    // Load filter state
    _filterActive = prefs.getBool('filter_active') ?? false;
    
    // Load weather city
    _weatherCity = prefs.getString('weather_city') ?? 'Amsterdam';
    
    // Load auto-location preference
    _useAutoLocation = prefs.getBool('auto_location') ?? true;
    _currentPosition = prefs.getString('current_position');
    
    await loadNews();
  }

  Future<void> loadNews({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final articles = await _repository.fetchNews();
      _articles = articles;
      _applyFilter();
    } catch (e) {
      _error = e.toString();
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
      
      // Save position
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_position', _currentPosition!);
      
      notifyListeners();
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