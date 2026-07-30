import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/article.dart';

const _kCacheTtlDays = 1;

class ArticleCacheService {
  static String? _cacheDir;

  static Future<String> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getTemporaryDirectory();
    _cacheDir = '${appDir.path}/article_cache';
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _cacheDir!;
  }

  static Future<void> cacheArticles(List<Article> articles) async {
    try {
      final dir = await _dir;
      final payload = articles.map((a) => a.toJson()).toList();
      final encoded = jsonEncode(payload);
      await File('$dir/articles.json').writeAsString(encoded);
      await File('$dir/timestamp').writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      debugPrint('Cache write failed: $e');
    }
  }

  static Future<List<Article>> getCachedArticles() async {
    try {
      final dir = await _dir;
      final file = File('$dir/articles.json');
      if (!await file.exists()) return [];

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];

      return compute(_decodeArticles, jsonString);
    } catch (e) {
      debugPrint('Cache read failed: $e');
      return [];
    }
  }

  static List<Article> _decodeArticles(String jsonString) {
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> isCacheValid() async {
    try {
      final dir = await _dir;
      final file = File('$dir/timestamp');
      if (!await file.exists()) return false;
      final ts = int.tryParse(await file.readAsString());
      if (ts == null) return false;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      return age.inDays < _kCacheTtlDays;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearCache() async {
    try {
      final dir = await _dir;
      final d = Directory(dir);
      if (await d.exists()) {
        await d.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Cache clear failed: $e');
    }
  }

  // ── Article content cache (full text) ──

  static Future<String?> getArticleContent(String articleId) async {
    try {
      final dir = await _dir;
      final file = File('$dir/content_$articleId.txt');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheArticleContent(
      String articleId, String content) async {
    try {
      final dir = await _dir;
      await File('$dir/content_$articleId.txt').writeAsString(content);
    } catch (_) {}
  }

  /// Cache full article content from URLs in background.
  /// First caches descriptions as fast fallback, then fetches full HTML.
  static Future<void> cacheArticlesContent(List<Article> articles) async {
    // First: cache descriptions for all articles (instant, no network)
    for (final article in articles) {
      if (article.description.isNotEmpty) {
        await cacheArticleContent(article.id, article.description);
      }
    }

    // Then: fetch full content from URLs in parallel (max 5 at a time)
    final batches = <List<Article>>[];
    for (var i = 0; i < articles.length; i += 5) {
      batches.add(articles.sublist(
        i,
        i + 5 > articles.length ? articles.length : i + 5,
      ));
    }
    for (final batch in batches) {
      await Future.wait(
        batch.map((article) async {
          final url = article.url ?? article.link;
          if (url.isEmpty) return;
          try {
            final response = await http
                .get(
                  Uri.parse(url),
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  },
                )
                .timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              final content = _extractArticleText(response.body);
              if (content.isNotEmpty) {
                await cacheArticleContent(article.id, content);
              }
            }
          } catch (_) {}
        }),
        eagerError: false,
      );
    }
  }

  /// Extract readable text from HTML
  static String _extractArticleText(String html) {
    var text = html.replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    text = text.replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');
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
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > 10000) {
      text = '${text.substring(0, 10000)}...';
    }
    return text;
  }
}
