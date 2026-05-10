import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class ArticleCacheService {
  static const String _cachedArticlesKey = 'cached_articles';
  static const String _lastFetchKey = 'last_fetch_time';
  static const Duration _cacheValidity = Duration(hours: 2); // Cache for 2 hours

  static Future<void> cacheArticles(List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((a) => a.toJson()).toList();
      await prefs.setString(_cachedArticlesKey, jsonEncode(jsonList));
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching articles: $e');
    }
  }

  static Future<List<Article>> getCachedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cachedArticlesKey);
      
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((e) => Article.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading cached articles: $e');
    }
    return [];
  }

  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastFetchKey);
      
      if (lastFetch == null) return false;
      
      final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      return DateTime.now().difference(lastFetchTime) < _cacheValidity;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedArticlesKey);
      await prefs.remove(_lastFetchKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
