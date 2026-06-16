import 'package:flutter/material.dart';
import '../models/article.dart';

class NewsProvider with ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;

  Future<void> loadNews() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock data
      _articles = [
        const Article(
          id: '1',
          title: 'Test Nieuws 1',
          source: 'Test Bron',
          link: 'https://test.nl/1',
          url: 'https://test.nl/1',
          pubDate: '2023-01-01',
        ),
        const Article(
          id: '2',
          title: 'Test Nieuws 2',
          source: 'Test Bron',
          link: 'https://test.nl/2',
          url: 'https://test.nl/2',
          pubDate: '2023-01-02',
        ),
      ];
    } catch (e) {
      // Error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}