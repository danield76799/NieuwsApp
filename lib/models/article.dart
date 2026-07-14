import 'package:intl/intl.dart';

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

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(pubDate);
    
    if (diff.inMinutes < 1) return 'zojuist';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min geleden';
    if (diff.inHours < 24) return '${diff.inHours} uur geleden';
    if (diff.inDays < 7) return '${diff.inDays} dagen geleden';
    
    return DateFormat('d MMM').format(pubDate);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'content': content,
    'link': link,
    'url': url,
    'pubDate': pubDate.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
    'thumbnailUrl': thumbnailUrl,
    'imageUrl': imageUrl,
    'source': source,
    'category': category,
    'author': author,
  };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    content: json['content'],
    link: json['link'] ?? json['url'] ?? '',
    url: json['url'] ?? json['link'] ?? '',
    pubDate: json['pubDate'] != null 
        ? DateTime.parse(json['pubDate']) 
        : DateTime.now(),
    publishedAt: json['publishedAt'] != null 
        ? DateTime.parse(json['publishedAt']) 
        : null,
    thumbnailUrl: json['thumbnailUrl'] ?? json['imageUrl'],
    imageUrl: json['imageUrl'] ?? json['thumbnailUrl'],
    source: json['source'] ?? 'Onbekend',
    category: json['category'],
    author: json['author'],
  );
}
