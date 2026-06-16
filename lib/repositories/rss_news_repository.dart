import 'dart:async';
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

      // Fetch all feeds in parallel with timeout
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
            return <Article>[];
          }
        } catch (e) {
          return <Article>[];
        }
      }).toList();

      final results = await Future.wait(futures);
      var allArticles = results.expand((e) => e).toList();

      // Sort by date (newest first)
      allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

      // Limit to 50 articles for faster loading
      if (allArticles.length > 50) {
        allArticles = allArticles.take(50).toList();
      }

      return allArticles;
    } catch (e) {
      print('Error fetching news: $e');
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