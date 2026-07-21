import 'dart:async';
import 'package:flutter/foundation.dart';
import "../models/article.dart";
import "../services/rss_parser_service.dart";
import "../services/feed_service.dart";
import "news_repository.dart";

class RssNewsRepository implements NewsRepository {
  @override
  Future<List<Article>> fetchNews({bool forceRefresh = false}) async {
    try {
      // Get feeds from SharedPreferences
      final feeds = await FeedService.getFeeds();
      
      if (feeds.isEmpty) {
        return [];
      }

      // Fetch all feeds in parallel with timeout
      final futures = feeds.map((source) async {
        try {
          // 5s timeout per feed (sneller dan 10s)
          final articles = await RssParserService.parseRssFeed(source["url"]!).timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );
          
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
          return <Article>[];
        }
      }).toList();

      // Wait for all feeds with 8s total timeout
      final results = await Future.wait(futures).timeout(
        const Duration(seconds: 8),
        onTimeout: () => [],
      );
      
      var allArticles = results.expand((e) => e).toList();

      // Deduplicate by link/id to reduce list size and UI rebuilds.
      final seen = <String>{};
      allArticles = allArticles.where((article) {
        final key = article.link.isEmpty ? article.id : article.link;
        return seen.add(key);
      }).toList();

      // Sort by date (newest first)
      allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

      // Limit to 30 articles for faster loading (was 50)
      if (allArticles.length > 30) {
        allArticles = allArticles.take(30).toList();
      }

      return allArticles;
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return [];
    }
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