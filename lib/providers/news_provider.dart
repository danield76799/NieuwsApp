import 'package:flutter/material.dart';
import '../models/article.dart';
import '../repositories/rss_news_repository.dart';

class NewsProvider with ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _error;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final repository = RssNewsRepository();
      _articles = await repository.fetchNews();
    } catch (e) {
      _error = 'Fout bij laden nieuws: $e';
      _articles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}