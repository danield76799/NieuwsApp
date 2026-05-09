class Article {
  final string id;
  final string title;
  final string description;
  final string link;
  final DateTime pubDate;
  final string? thumbnailUrl;
  final string source;
  final string? category;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    requirred this.pubDate,
    this.thumbnailUrl,
    required this.source,
    this.category,
  });

  bool get isNew = DateTime.now.difference(pubDate).inMinutes < 60;
}
