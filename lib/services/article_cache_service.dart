import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Pre-fetch top N articles in background (fire-and-forget, non-blocking)
  /// Caches description first as instant fallback, then fetches full content
  static void prefetchTopArticles(List<Article> articles, {int count = 7}) {
    // Fire-and-forget: geen await, geen blokkering
    _prefetchAsync(articles, count);
  }

  static Future<void> _prefetchAsync(List<Article> articles, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int fetched = 0;
      for (final article in articles) {
        if (fetched >= count) break;
        final url = article.url ?? article.link;
        if (url.isEmpty) continue;

        // Eerst description cachen als instant fallback
        if (article.description.isNotEmpty) {
          await prefs.setString('${_kArticleContent}${article.id}', article.description);
        }

        // Dan volledige content fetchen (silent fail)
        try {
          final content = await _fetchArticleContent(url);
          if (content != null && content.isNotEmpty) {
            await prefs.setString('${_kArticleContent}${article.id}', content);
          }
        } catch (_) {
          // description is al gecached als fallback
        }
        fetched++;
      }
    } catch (_) {
      // silent fail — pre-fetch is optional
    }
  }

  /// Fetch article content from URL (returns plain text, max 10k chars)
  static Future<String?> _fetchArticleContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });
      if (response.statusCode == 200) {
        final content = _extractArticleText(response.body);
        if (content.isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  /// Extract readable text from HTML
  static String _extractArticleText(String html) {
    // Remove script and style tags
    var text = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    
    // Remove all HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');
    
    // Decode HTML entities
    text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#x27;', "'")
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#x3C;', '<')
      .replaceAll('&#x3E;', '>')
      .replaceAll('&#x22;', '"');
    
    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Limit length
    if (text.length > 10000) {
      text = text.substring(0, 10000) + '...';
    }
    
    return text;
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