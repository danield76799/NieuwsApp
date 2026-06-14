import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/article.dart';

/// Service voor het scrapen van nieuws.nl
class NieuwsNlService {
  /// Haal artikelen op van nieuws.nl RSS feed
  Future<List<Article>> getArticles() async {
    try {
      // nieuws.nl RSS feed
      final response = await http.get(
        Uri.parse('https://www.nieuws.nl/rss'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; NieuwsApp/1.0)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseRssFeed(response.body);
      } else {
        throw Exception('Failed to load nieuws.nl: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nieuws.nl: $e');
      return [];
    }
  }

  /// Parse RSS XML naar Article objecten
  List<Article> _parseRssFeed(String xmlData) {
    final articles = <Article>[];
    
    // Eenvoudige XML parsing met regex (voor RSS feeds)
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final items = itemRegex.allMatches(xmlData);
    
    for (final item in items) {
      final itemXml = item.group(1) ?? '';
      
      final title = _extractXmlValue(itemXml, 'title');
      final description = _extractXmlValue(itemXml, 'description');
      final link = _extractXmlValue(itemXml, 'link');
      final pubDate = _extractXmlValue(itemXml, 'pubDate');
      final imageUrl = _extractImageFromXml(itemXml);
      
      if (title.isNotEmpty && link.isNotEmpty) {
        articles.add(Article(
          id: link.hashCode.toString(),
          title: _decodeHtmlEntities(title),
          description: _decodeHtmlEntities(description),
          content: _decodeHtmlEntities(description),
          link: link,
          url: link,
          pubDate: _parseRssDate(pubDate),
          imageUrl: imageUrl,
          source: 'nieuws.nl',
          publishedAt: _parseRssDate(pubDate),
          author: null,
          category: null,
        ));
      }
    }
    
    return articles;
  }

  /// Extract waarde uit XML tag
  String _extractXmlValue(String xml, String tag) {
    final regex = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extract afbeelding uit RSS item (uit enclosure of media:content)
  String? _extractImageFromXml(String xml) {
    // Probeer media:content
    final mediaRegex = RegExp(r'<media:content[^>]*url="([^"]*)"');
    final mediaMatch = mediaRegex.firstMatch(xml);
    if (mediaMatch != null) return mediaMatch.group(1);
    
    // Probeer enclosure
    final enclosureRegex = RegExp(r'<enclosure[^>]*url="([^"]*)"');
    final enclosureMatch = enclosureRegex.firstMatch(xml);
    if (enclosureMatch != null) return enclosureMatch.group(1);
    
    // Probeer img tag in description
    final imgRegex = RegExp(r'<img[^>]*src="([^"]*)"');
    final imgMatch = imgRegex.firstMatch(xml);
    if (imgMatch != null) return imgMatch.group(1);
    
    return null;
  }

  /// Parse RSS datum formaat
  DateTime _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    
    try {
      // RSS datum formaat: Mon, 06 Sep 2021 12:00:00 GMT
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  /// Decode HTML entities
  String _decodeHtmlEntities(String text) {
    return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&apos;', "'");
  }

  /// Haal specifieke categorie op
  Future<List<Article>> getCategoryArticles(String category) async {
    // Map categorieën naar nieuws.nl URLs
    final categoryUrls = {
      'algemeen': 'https://www.nieuws.nl/rss',
      'economie': 'https://www.nieuws.nl/economie/rss',
      'sport': 'https://www.nieuws.nl/sport/rss',
      'tech': 'https://www.nieuws.nl/tech/rss',
      'entertainment': 'https://www.nieuws.nl/entertainment/rss',
    };
    
    final url = categoryUrls[category.toLowerCase()];
    if (url == null) return getArticles();
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; NieuwsApp/1.0)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseRssFeed(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching category: $e');
      return [];
    }
  }
}