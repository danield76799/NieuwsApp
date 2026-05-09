import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';

/// Service voor het ophalen van nieuws via nieuws.nl RSS feed
class NewsApiService {
  static const String _rssUrl = 'https://nieuws.nl/sitemap/news.xml';
  
  /// Haal nieuws op van nieuws.nl RSS feed
  Future<List<Article>> getTopHeadlines({
    String country = 'nl',
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(_rssUrl),
        headers: {
          'Accept': 'application/rss+xml, application/xml, text/xml',
          'User-Agent': 'NieuwsApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        List<Article> articles = [];
        
        for (var item in items) {
          final title = item.findElements('title').firstOrNull?.text ?? '';
          final link = item.findElements('link').firstOrNull?.text ?? '';
          final description = item.findElements('description').firstOrNull?.text ?? '';
          final pubDate = item.findElements('pubDate').firstOrNull?.text ?? '';
          final enclosure = item.findElements('enclosure').firstOrNull;
          
          // Extract image URL from enclosure
          String? imageUrl;
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url');
          }
          
          // Extract category from link
          String articleCategory = 'algemeen';
          final categoryMatch = RegExp(r'https://nieuws\.nl/([^/]+)/').firstMatch(link);
          if (categoryMatch != null) {
            articleCategory = categoryMatch.group(1) ?? 'algemeen';
          }
          
          // Filter by category if specified
          if (category != null && category != 'all' && articleCategory != category) {
            continue;
          }
          
          articles.add(Article(
            id: link.hashCode.toString(),
            title: title,
            description: _cleanDescription(description),
            content: _cleanDescription(description),
            url: link,
            imageUrl: imageUrl,
            source: 'nieuws.nl',
            publishedAt: _parseDate(pubDate),
            author: null,
            category: articleCategory,
          ));
        }
        
        // Pagination
        final startIndex = (page - 1) * pageSize;
        final endIndex = startIndex + pageSize;
        
        if (startIndex >= articles.length) {
          return [];
        }
        
        return articles.sublist(
          startIndex,
          endIndex > articles.length ? articles.length : endIndex,
        );
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }
  
  /// Zoek nieuws op keywords (client-side filtering)
  Future<List<Article>> searchNews({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final allNews = await getTopHeadlines(page: 1, pageSize: 100);
    
    final filtered = allNews.where((article) {
      final searchText = '${article.title} ${article.description}'.toLowerCase();
      return searchText.contains(query.toLowerCase());
    }).toList();
    
    // Pagination
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    
    if (startIndex >= filtered.length) {
      return [];
    }
    
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }
  
  /// Clean HTML from description
  String _cleanDescription(String html) {
    // Remove CDATA tags
    var text = html.replaceAll(RegExp(r'<\!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');
    
    // Remove img tags
    text = text.replaceAll(RegExp(r'<img[^>]*>'), '');
    
    // Remove other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&nbsp;', ' ');
    
    // Trim whitespace
    text = text.trim();
    
    // Limit length
    if (text.length > 300) {
      text = text.substring(0, 300) + '...';
    }
    
    return text;
  }
  
  /// Parse RSS date to DateTime
  DateTime _parseDate(String rssDate) {
    try {
      // RSS date format: Sat, 09 May 2026 05:38:38 +0200
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      final match = RegExp(r'([A-Z][a-z]{2}), (\d{1,2}) ([A-Z][a-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})').firstMatch(rssDate);
      
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final month = months[match.group(3)!] ?? 1;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = int.parse(match.group(7)!);
        
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    return DateTime.now();
  }
}
