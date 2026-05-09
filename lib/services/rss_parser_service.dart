import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert' show utf8, latin1;
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
        String body;
        try {
          body = utf8.decode(response.bodyBytes);
        } catch (_) {
          body = latin1.decode(response.bodyBytes);
        }
        
        final document = XmlDocument.parse(body);
        final items = document.findAllElements('item');
        
        List<Article> articles = [];
        
        for (var item in items) {
          try {
            final title = item.findElements('title').firstOrNull?.text ?? '';
            final link = item.findElements('link').firstOrNull?.text ?? '';
            final description = item.findElements('description').firstOrNull?.text ?? '';
            final pubDateStr = item.findElements('pubDate').firstOrNull?.text ?? '';
            
            if (title.isEmpty || link.isEmpty) continue;
            
            String? thumbnailUrl = _extractThumbnail(item);
            
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

  String? _extractThumbnail(XmlElement item) {
    // 1. Try <enclosure type="image/..."> - standard RSS for images
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final type = enclosure.getAttribute('type') ?? '';
      if (type.startsWith('image/')) {
        return enclosure.getAttribute('url');
      }
    }
    
    // 2. Try <media:content medium="image">
    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final medium = mediaContent.getAttribute('medium') ?? '';
      if (medium == 'image') {
        return mediaContent.getAttribute('url');
      }
      // Also check if url contains common image extensions
      final url = mediaContent.getAttribute('url') ?? '';
      if (url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.webp')) {
        return url;
      }
    }
    
    // 3. Try <media:thumbnail> - common in news feeds
    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }
    
    // 4. Try <media:description> with embedded img tag
    final mediaDesc = item.findElements('media:description').firstOrNull;
    if (mediaDesc != null) {
      final imgUrl = _extractImgFromHtml(mediaDesc.text);
      if (imgUrl != null) return imgUrl;
    }
    
    // 5. Try <content:encoded> - often has full HTML with images
    final contentEncoded = item.findElements('content:encoded').firstOrNull;
    if (contentEncoded != null) {
      final imgUrl = _extractImgFromHtml(contentEncoded.text);
      if (imgUrl != null) return imgUrl;
    }
    
    // 6. Try <description> with img tag
    final description = item.findElements('description').firstOrNull;
    if (description != null) {
      final imgUrl = _extractImgFromHtml(description.text);
      if (imgUrl != null) return imgUrl;
    }
    
    return null;
  }
  
  String? _extractImgFromHtml(String html) {
    if (html.isEmpty) return null;
    
    // Try standard img src pattern
    final imgRegex = RegExp(r'<img[^>]+src=["\']([^"\']+)["\']');
    final match = imgRegex.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    
    // Try src= without quotes (less common)
    final imgRegex2 = RegExp(r'<img[^>]+src=([^\s>]+)');
    final match2 = imgRegex2.firstMatch(html);
    if (match2 != null && match2.groupCount >= 1) {
      String url = match2.group(1)!;
      // Remove surrounding quotes if any
      url = url.replaceAll('"', '').replaceAll("'", '');
      return url;
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
    
    // Decode HTML entities
    text = _decodeHtmlEntities(text);
    
    text = text.trim();
    if (text.length > 300) {
      text = text.substring(0, 300) + '...';
    }
    return text;
  }

  String _decodeHtmlEntities(String text) {
    final entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#039;': "'",
      '&#39;': "'",
      '&nbsp;': ' ',
      '&ndash;': '–',
      '&mdash;': '—',
      '&hellip;': '...',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
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
      
      try {
        return DateTime.parse(rssDate);
      } catch (_) {}
      
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }
}