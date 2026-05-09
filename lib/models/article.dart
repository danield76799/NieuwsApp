import "package:hive/hive.dart";

part "article.g.dart";

@HiveType(typeId: 0)
class Article {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String link;
  
  @HiveField(4)
  final DateTime pubDate;
  
  @HiveField(5)
  final String? thumbnailUrl;
  
  @HiveField(6)
  final String source;
  
  @HiveField(7)
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
