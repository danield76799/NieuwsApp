import "../models/article.dart";

abstract class NewsRepository {
  Future<List<Article>> fetchNews();
  Future<List<Article>> fetchNewsWithFilter(List<String> keywords);
  List<Article> filterByKeywords(List<Article> articles, List<String> keywords);
}
