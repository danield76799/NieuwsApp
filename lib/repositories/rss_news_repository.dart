import "../models/article.dart";
import "../services/rss_parser_service.dart";
import "../services/storage_service.dart";
import "news_repository.dart";

class RssNewsRepository implements NewsRepository {
  final RssParserService _rssService;
  final StorageService _storage;

  final List<Map<String, String>> _sources = [
    {"name": "Nieuws.nl", "url": "https://www.nieuws.nl/rss"},
    {"name": "Tweakers", "url": "https://tweakers.net/feeds/nieuws.xml"},
  ];

  RssNewsRepository(this._rssService, this._storage);

  @override
  Future<List<Article>> fetchNews() async {
    List<Article> allArticles = [];
    List<Exception> errors = [];

    for (final source in _sources) {
      try {
        final articles = await _rssService.fetchArticles(
          source["url"]!,
          source["name"]!
        );
        allArticles.addAll(articles);
      } catch (e) {
        errors.add(Exception("${source["name"]}: $e"));
      }
    }

    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    if (allArticles.isNotEmpty) {
      await _storage.cacheArticles(allArticles);
    }

    if (allArticles.isEmpty && errors.isNotEmpty) {
      final cached = await _storage.getCachedArticles();
      if (cached.isNotEmpty) return cached;
      throw Exception("Geen internet en geen cache beschikbaar");
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
