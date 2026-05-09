import '../models/article.dart';

class StorageService {
  // Simple in-memory cache - no external dependencies needed
  List<Article>? _cachedArticles;

  Future<void> cacheArticles(List<Article> articles) async {
    _cachedArticles = articles;
  }

  Future<List<Article>> getCachedArticles() async {
    return _cachedArticles ?? [];
  }
}