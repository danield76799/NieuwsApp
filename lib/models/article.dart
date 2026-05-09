class Article {
  final String id;
  final String title;
  final String description;
  final String? content;
  final String link;
  final String? url;
  final DateTime pubDate;
  final DateTime? publishedAt;
  final String? thumbnailUrl;
  final String? imageUrl;
  final String source;
  final String? category;
  final String? author;

  Article({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    required this.link,
    this.url,
    required this.pubDate,
    this.publishedAt,
    this.thumbnailUrl,
    this.imageUrl,
    required this.source,
    this.category,
    this.author,
  });

  bool get isNew => DateTime.now().difference(pubDate).inMinutes < 60;
}