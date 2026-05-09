import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';
import '../models/article.dart';

class RssParserService {
  static const String _nieuwsNlFeed = 'https://www.nieuws.nl/rss';
  static const String _tweakersFeed = 'https://tweakers.net/feeds/nieuws.xml';

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
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        List<Article> articles = [];
        
        for (var item in items) {
          try {
            final title = item.findElements('title').firstOrNull?.text ?? '';
            final link = item.findElements('link').firstOrNull?.text ?? '';
            final description = item.findElements('description').firstOrNull?.text ?? '';
            final pubDateStr = item.findElements('pubDate').firstOrNull?.text ?? '';
            
            if (title.isEmpty || link.isEmpty) continue;
            
            // Try multiple sources for thumbnail
            String? thumbnailUrl = _extractThumbnail(item, description);
            
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
            continue;
          }
        }
        
        return articles;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('RSS parse error: $e');
    }
  }

  String? _extractThumbnail(XmlElement item, String description) {
    // Try enclosure first (common for podcasts/images)
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final type = enclosure.getAttribute('type') ?? '';
      if (type.startsWith('image/')) {
        return enclosure.getAttribute('url');
      }
    }
    
    // Try media:content
    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final medium = mediaContent.getAttribute('medium') ?? '';
      if (medium == 'image' || mediaContent.getAttribute('url')?.contains('image') == true) {
        return mediaContent.getAttribute('url');
      }
    }
    
    // Try media:thumbnail
    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      return mediaThumbnail.getAttribute('url');
    }
    
    // Try media:description with img tag
    final mediaDescription = item.findElements('media:description').firstOrNull;
    if (mediaDescription != null) {
      final imgMatch = RegExp(r'<img[^>]+src=["\']([^"\']+)["\']').firstMatch(mediaDescription.text);
      if (imgMatch != null) {
        return imgMatch.group(1);
      }
    }
    
    // Fallback: extract from description HTML
    final imgMatch = RegExp(r'<img[^>]+src=["\']([^"\']+)["\']').firstMatch(description);
    if (imgMatch != null) {
      return imgMatch.group(1);
    }
    
    return null;
  }

  String _cleanText(String text) {
    if (text.isEmpty) return '';
    
    // Remove CDATA
    text = text.replaceAll(RegExp(r'<\!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');
    
    // Remove img tags
    text = text.replaceAll(RegExp(r'<img[^>]*>'), '');
    
    // Remove other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities using dart:convert
    text = _decodeHtmlEntities(text);
    
    text = text.trim();
    if (text.length > 300) {
      text = text.substring(0, 300) + '...';
    }
    return text;
  }

  String _decodeHtmlEntities(String text) {
    // Use htmlEscape from dart:html style replacement for common entities
    final Map<String, String> entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#039;': "'",
      '&#39;': "'",
      '&nbsp;': ' ',
      '&ndash;': '–',
      '&mdash;': '—',
      '&hellip;': '...',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
      '&euro;': '€',
      '&pound;': '£',
      // Dutch special chars
      '&eacute;': 'é',
      '&egrave;': 'è',
      '&ecirc;': 'ê',
      '&auml;': 'ä',
      '&ouml;': 'ö',
      '&uuml;': 'ü',
      '&iacute;': 'í',
      '&oacute;': 'ó',
      '&uacute;': 'ú',
      '&ntilde;': 'ñ',
      '&ccedil;': 'ç',
      '&aring;': 'å',
      '&oslash;': 'ø',
      '&#8217;': ''',
      '&#8216;': ''',
      '&#8220;': '"',
      '&#8221;': '"',
      '&#8211;': '–',
      '&#8212;': '—',
      '&#160;': ' ',
      '&#169;': '©',
      '&#174;': '®',
      '&#8482;': '™',
    };
    
    for (var entry in entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    
    // Handle numeric entities
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!))
    );
    
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16))
    );
    
    return text;
  }

  DateTime _parseDate(String rssDate) {
    if (rssDate.isEmpty) return DateTime.now();
    
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      // Standard RSS format: "Sat, 09 May 2026 05:38:38 +0200"
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
      
      // Try ISO 8601
      try {
        return DateTime.parse(rssDate);
      } catch (_) {}
      
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }
}