class Article {
  final String id;
  final String title;
  final String source;
  final String description;
  final String? content;
  final String link;
  final String url;
  final String pubDate;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? publishedAt;
  final String? author;
  final String? category;
  final bool isNew;

  const Article({
    required this.id,
    required this.title,
    required this.source,
    this.description = '',
    this.content,
    required this.link,
    required this.url,
    required this.pubDate,
    this.imageUrl,
    this.thumbnailUrl,
    this.publishedAt,
    this.author,
    this.category,
    this.isNew = false,
  });
}