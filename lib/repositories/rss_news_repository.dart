import "../models/article.dart";
import "../services/rss_parser_service.dart";
import "../services/storage_service.dart";
import "news_repository.dart";

class RssNewsRepository implements NewsRepository {
  final RssParserService _rssService;
  final StorageService _storage;

  final List<Map<String, String>> _sources = [
    // Nieuws.nl feeds - multiple fallback options
    {"name": "Nieuws.nl", "url": "https://www.nieuws.nl/rss"},
    // Tweakers feed
    {"name": "Tweakers", "url": "https://tweakers.net/feeds/nieuws.xml"},
    // Additional fallback for nieuws.nl via sitemap
    {"name": "Nieuws.nl Sitemap", "url": "https://nieuws.nl/sitemap/news.xml"},
  ];

  RssNewsRepository(this._rssService, this._storage);

  @override
  Future<List<Article>> fetchNews() async {
    List<Article> allArticles = [];
    List<String> errors = [];

    for (final source in _sources) {
      try {
        final articles = await _rssService.fetchArticles(
          source["url"]!,
          source["name"]!
        );
        if (articles.isNotEmpty) {
          allArticles.addAll(articles);
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