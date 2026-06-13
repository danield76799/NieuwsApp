import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

const _kCachedArticles = 'cached_articles';
const _kCacheTimestamp = 'cache_timestamp';
const _kCacheTtlDays = 1;
const _kArticleContent = 'article_content_';

class ArticleCacheService {
  static Future<void> cacheArticles(List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = articles.map((a) => a.toJson()).toList();
      final encoded = jsonEncode(payload);
      await prefs.setString(_kCachedArticles, encoded);
      await prefs.setInt(_kCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      await _cacheFallback(articles);
    }
  }

  static Future<List<Article>> getCachedArticles() async {
    final jsonString = await _read(key: _kCachedArticles, fallback: '');
    if (jsonString == null || jsonString.isEmpty) return <Article>[];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> isCacheValid() async {
    final ts = await _read(key: _kCacheTimestamp, fallback: null);
    if (ts == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    return age.inDays < _kCacheTtlDays;
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedArticles);
      await prefs.remove(_kCacheTimestamp);
    } catch (_) {
      await _fallbackClear();
    }
  }

  static Future<String?> getArticleContent(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString('${_kArticleContent}$articleId');
    return content;
  }

  static Future<void> cacheArticleContent(String articleId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kArticleContent}$articleId', content);
  }

  static Future<void> cacheArticlesContent(List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    for (final article in articles) {
      if (article.description != null && article.description!.isNotEmpty) {
        await cacheArticleContent(article.id, article.description!);
      }
    }
  }

  static Future<T?> _read<T>({required String key, required T fallback}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(key);
      return value == null ? fallback : value as T;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> _cacheFallback(List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final a in articles) {
        await prefs.setString('article_${a.id}', jsonEncode(a.toJson()));
      }
    } catch (_) {
      // no-op
    }
  }

  static Future<void> _fallbackClear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      await Future.wait(
        keys.where((k) => k.startsWith('article_')).map(prefs.remove),
      );
    } catch (_) {
      // no-op
    }
  }
}