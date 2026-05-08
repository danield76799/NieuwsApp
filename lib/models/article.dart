import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model voor een nieuws artikel
class Article {
  final String id;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;
  final String? author;
  final String? category;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
    this.author,
    this.category,
  });

  /// Factory constructor van JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['url']?.hashCode.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Geen titel',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
      source: json['source']?['name'] ?? 'Onbekend',
      publishedAt: _parseDate(json['publishedAt']),
      author: json['author'],
      category: json['category'],
    );
  }

  /// Naar JSON voor lokale opslag
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'category': category,
    };
  }

  /// Parse datum van API formaat
  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Check of artikel minder dan 1 uur oud is
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inHours < 1;
  }

  /// Geformatteerde publicatietijd
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 1) {
      return 'Zojuist';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} uur geleden';
    } else {
      return DateFormat('d MMM').format(publishedAt);
    }
  }

  @override
  String toString() {
    return 'Article(title: $title, source: $source, publishedAt: $publishedAt)';
  }
}
