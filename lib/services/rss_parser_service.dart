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
    // 1. Try enclosure
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final type = enclosure.getAttribute('type') ?? '';
      if (type.startsWith('image/')) {
        return enclosure.getAttribute('url');
      }
    }
    
    // 2. Try media:content
    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final medium = mediaContent.getAttribute('medium') ?? '';
      if (medium == 'image') {
        return mediaContent.getAttribute('url');
      }
      final url = mediaContent.getAttribute('url') ?? '';
      if (url.contains('.jpg') || url.contains('.png')) {
        return url;
      }
    }
    
    // 3. Try media:thumbnail
    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      return mediaThumbnail.getAttribute('url');
    }
    
    // 4. Try content:encoded
    final contentEncoded = item.findElements('content:encoded').firstOrNull;
    if (contentEncoded != null) {
      final url = _extractImgFromHtml(contentEncoded.text);
      if (url != null) return url;
    }
    
    // 5. Try description
    final description = item.findElements('description').firstOrNull;
    if (description != null) {
      return _extractImgFromHtml(description.text);
    }
    
    return null;
  }
  
  String? _extractImgFromHtml(String html) {
    if (html.isEmpty) return null;
    
    // Simple regex for img src - use double quotes
    final match1 = RegExp(r'src="([^"]+)"').firstMatch(html);
    if (match1 != null) return match1.group(1);
    
    // Try single quotes
    final match2 = RegExp(r"src='([^']+)'").firstMatch(html);
    if (match2 != null) return match2.group(1);
    
    return null;
  }

  String _cleanText(String text) {
    if (text.isEmpty) return '';
    
    text = text.replaceAll(RegExp(r'<\!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');
    text = text.replaceAll(RegExp(r'<img[^>]*>'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
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
      '&ndash;': '-',
      '&mdash;': '-',
      '&hellip;': '...',
      '&#8217;': "'",
      '&#8216;': "'",
      '&#8220;': '"',
      '&#8221;': '"',
      '&#8211;': '-',
      '&#8212;': '-',
      '&#160;': ' ',
    };
    
    for (var entry in entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    
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
    if (rssDate.isEmpty) {
      print('Empty date string, returning epoch');
      return DateTime(1970, 1, 1);
    }
    
    try {
      // Try standard RSS format: Mon, 01 May 2026 12:00:00 GMT
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      // Match format: Day, DD Mon YYYY HH:MM:SS (with optional timezone)
      final match = RegExp(r'([A-Z][a-z]{2}),?\s+(\d{1,2})\s+([A-Z][a-z]{2,3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})').firstMatch(rssDate);
      
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        final month = months[monthStr.substring(0, 3)] ?? 1;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = int.parse(match.group(7)!);
        
        print('Parsed RSS date: $year-$month-$day $hour:$minute:$second');
        return DateTime(year, month, day, hour, minute, second);
      }
      
      // Try ISO 8601 format
      try {
        return DateTime.parse(rssDate);
      } catch (_) {}
      
      // Try Dutch format: 1 mei 2026 12:00
      final dutchMatch = RegExp(r'(\d{1,2})\s+([a-z]{3,9})\s+(\d{4})\s+(\d{1,2}):(\d{2})').firstMatch(rssDate.toLowerCase());
      if (dutchMatch != null) {
        final dutchMonths = {
          'jan': 1, 'januari': 1, 'feb': 2, 'februari': 2, 'mrt': 3, 'maart': 3,
          'apr': 4, 'april': 4, 'mei': 5, 'jun': 6, 'juni': 6,
          'jul': 7, 'juli': 7, 'aug': 8, 'augustus': 8, 'sep': 9, 'september': 9,
          'okt': 10, 'oktober': 10, 'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
        };
        final day = int.parse(dutchMatch.group(1)!);
        final month = dutchMonths[dutchMatch.group(2)!] ?? 1;
        final year = int.parse(dutchMatch.group(3)!);
        final hour = int.parse(dutchMatch.group(4)!);
        final minute = int.parse(dutchMatch.group(5)!);
        return DateTime(year, month, day, hour, minute);
      }
      
      print('Could not parse date: $rssDate');
    } catch (e) {
      print('Error parsing date "$rssDate": $e');
    }
    
    // Return epoch instead of now() to avoid showing old articles as new
    return DateTime(1970, 1, 1);
  }
}
