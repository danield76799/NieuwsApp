import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';

class RssParserService {
  Future<List<Article>> fetchArticles(String url, String sourceName) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/rss+xml, application/xml, text/xml',
          'User-Agent': 'PlusNews/1.0',
        },
      );

      if (response.statusCode == 200) {
        try {
          final document = XmlDocument.parse(response.body);
          final items = document.findAllElements('item');
          
          List<Article> articles = [];
          
          for (var item in items) {
            try {
              final title = item.findElements('title').firstOrNull?.text ?? '';
              final link = item.findElements('link').firstOrNull?.text ?? '';
              final description = item.findElements('description').firstOrNull?.text ?? '';
              final pubDateStr = item.findElements('pubDate').firstOrNull?.text ?? '';
              final enclosure = item.findElements('enclosure').firstOrNull;
              
              if (title.isEmpty || link.isEmpty) continue;
              
              String? thumbnailUrl;
              if (enclosure != null) {
                final type = enclosure.getAttribute('type') ?? '';
                if (type.startsWith('image/')) {
                  thumbnailUrl = enclosure.getAttribute('url');
                }
              }
              
              // Fallback: try media:content or media:thumbnail
              if (thumbnailUrl == null) {
                final mediaContent = item.findElements('media:content').firstOrNull;
                if (mediaContent != null) {
                  thumbnailUrl = mediaContent.getAttribute('url');
                }
              }
              
              if (thumbnailUrl == null) {
                final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
                if (mediaThumbnail != null) {
                  thumbnailUrl = mediaThumbnail.getAttribute('url');
                }
              }
              
              String articleCategory = sourceName.toLowerCase();
              final categoryMatch = RegExp(r'https?://[^/]+/([^/]+)/').firstMatch(link);
              if (categoryMatch != null) {
                articleCategory = categoryMatch.group(1) ?? sourceName.toLowerCase();
              }
              
              final pubDate = _parseDate(pubDateStr);
              
              articles.add(Article(
                id: link.hashCode.toString(),
                title: _cleanText(title),
                description: _cleanText(description),
                link: link,
                pubDate: pubDate,
                thumbnailUrl: thumbnailUrl,
                source: sourceName,
                category: articleCategory,
              ));
            } catch (e) {
              // Skip malformed item but continue parsing
              print('Skipping malformed item: $e');
              continue;
            }
          }
          
          return articles;
        } catch (e) {
          throw Exception('XML parse error for $sourceName: $e');
        }
      } else {
        throw Exception('HTTP ${response.statusCode} for $sourceName');
      }
    } catch (e) {
      throw Exception('Fetch error for $sourceName: $e');
    }
  }
  
  String _cleanText(String html) {
    if (html.isEmpty) return '';
    
    // Remove CDATA
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
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#8217;', "'")
      .replaceAll('&#8216;', "'")
      .replaceAll('&#8220;', '"')
      .replaceAll('&#8221;', '"')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&auml;', 'ä')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&ntilde;', 'ñ');
    
    text = text.trim();
    if (text.length > 300) {
      text = text.substring(0, 300) + '...';
    }
    return text;
  }
  
  DateTime _parseDate(String rssDate) {
    if (rssDate.isEmpty) return DateTime.now();
    
    try {
      // Standard RSS date format: "Sat, 09 May 2026 05:38:38 +0200"
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      // Try standard format first
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
      
      // Try ISO 8601 format
      try {
        return DateTime.parse(rssDate);
      } catch (_) {}
      
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }
}