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

    for (final source in feeds) {
      try {
        final articles = await RssParserService.parseRssFeed(source["url"]!);
        if (articles.isNotEmpty) {
          // Override source name with feed name from settings
          final articlesWithSource = articles.map((article) => Article(
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
            source: source["name"] ?? article.source, // Use feed name from settings
            category: article.category,
            author: article.author,
          )).toList();
          allArticles.addAll(articlesWithSource);
        }
      } catch (e) {
        errors.add("${source["name"]}: $e");
      }
    }

    // Remove duplicates based on link
    final seenLinks = <String>{};
    allArticles = allArticles.where((article) {
      if (seenLinks.contains(article.link)) {
        return false;
      }
      seenLinks.add(article.link);
      return true;
    }).toList();

    // Sort by date (newest first)
    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

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
