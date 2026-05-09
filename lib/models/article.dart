class Article {
  final String id;
  final String title;
  final String description;
  final String link;
  final DateTime pubDate;
  final String? thumbnailUrl;
  final String source;
  final String? category;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    this.thumbnailUrl,
    required this.source,
    this.category,
  });

  bool get isNew => DateTime.now().difference(pubDate).inMinutes < 60;
}