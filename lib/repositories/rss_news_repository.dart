import 'dart:async';
import "../models/article.dart";
import "../services/rss_parser_service.dart";
import "../services/storage_service.dart";
import "../services/feed_service.dart";
import "news_repository.dart";

class RssNewsRepository implements NewsRepository {
  final StorageService _storage;

  RssNewsRepository(this._storage);

  @override
  Future<List<Article>> fetchNews() async {
    List<Article> allArticles = [];
    List<String> errors = [];

    // Get feeds from SharedPreferences
    final feeds = await FeedService.getFeeds();

    // Fetch all feeds in parallel for much faster loading
    final futures = feeds.map((source) async {
      try {
        // Add timeout to prevent hanging on slow feeds
        final completer = Completer<dynamic>();
        final timer = Timer(const Duration(seconds: 10), () {
          completer.completeError("Timeout: Feed ${source["name"]} is te traag");
        });

        try {
          final articles = await RssParserService.parseRssFeed(source["url"]!);
          timer.cancel();
          if (articles.isNotEmpty) {
            return articles.map((article) => Article(
              id: article.id,
              title: article.title,
              description: article.description,
              content: article.content,
              link: article.link,
              url: article.url,
              pubDate: article.pubDate,
              publishedAt: article.publishedAt,
              thumbnailUrl: article.thumbnailUrl,
              imageUrl: article.imageUrl,
              source: source["name"] ?? article.source,
              category: article.category,
              author: article.author,
            )).toList();
          }
          return <Article>[];
        } catch (e) {
          timer.cancel();
          errors.add("${source["name"]}: $e");
          return <Article>[];
        }
      } catch (e) {
        errors.add("${source["name"]}: $e");
        return <Article>[];
      }
    }).toList();

    // Wait for all feeds to complete in parallel
    final results = await Future.wait(futures);
    
    // Collect all articles
    for (final articles in results) {
      allArticles.addAll(articles);
    }

    // Remove duplicates based on normalized link AND title similarity
    final seenLinks = <String>{};
    final seenTitles = <String>{};
    allArticles = allArticles.where((article) {
      // Normalize link
      final normalizedLink = article.link.replaceAll(RegExp(r'[?#].*$'), '').toLowerCase();
      if (seenLinks.contains(normalizedLink)) {
        return false;
      }
      seenLinks.add(normalizedLink);
      
      // Also check title similarity (some articles have different URLs but same title)
      final normalizedTitle = article.title.toLowerCase().trim();
      if (seenTitles.contains(normalizedTitle)) {
        return false;
      }
      seenTitles.add(normalizedTitle);
      
      return true;
    }).toList();

    // Sort by date (newest first)
    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    // Limit to 50 articles for faster loading
    if (allArticles.length > 50) {
      allArticles = allArticles.take(50).toList();
    }

    if (allArticles.isNotEmpty) {
      await _storage.cacheArticles(allArticles);
    }

    if (allArticles.isEmpty && errors.isNotEmpty) {
      final cached = await _storage.getCachedArticles();
      if (cached.isNotEmpty) return cached;
      throw Exception("Kon nieuws niet laden: " + errors.join(", "));
    }

    return allArticles;
  }

  @override
  List<Article> filterByKeywords(List<Article> articles, List<String> keywords) {
    if (keywords.isEmpty) return articles;

    final lowerKeywords = keywords.map((k) => k.toLowerCase().trim()).toList();

    return articles.where((article) {
      final searchText = "${article.title} ${article.description}".toLowerCase();
      return lowerKeywords.any((keyword) => searchText.contains(keyword));
    }).toList();
  }

  @override
  Future<List<Article>> fetchNewsWithFilter(List<String> keywords) async {
    final articles = await fetchNews();
    return filterByKeywords(articles, keywords);
  }
}
