import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';

class RssParserService {
  static final _allowedSchemes = ['http', 'https'];
  
  static bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return _allowedSchemes.contains(uri.scheme);
    } catch (e) {
      return false;
    }
  }
  
  static String _sanitizeHtml(String? text) {
    if (text == null || text.isEmpty) return '';
    
    // First remove all HTML tags (including multiline tags with spaces)
    var sanitized = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false, dotAll: true), '');
    
    // Remove script and style content
    sanitized = sanitized
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');
    
    // Remove common ad/tracking URLs and image references
    sanitized = sanitized
      .replaceAll(RegExp(r'https?://\S+\.(?:jpg|jpeg|png|gif|webp|svg)\S*', caseSensitive: false), '')
      .replaceAll(RegExp(r'https?://r\.testifier\.nl/\S*', caseSensitive: false), '')
      .replaceAll(RegExp(r'https?://\S*\.newsifier\.com/\S*', caseSensitive: false), '')
      .replaceAll(RegExp(r'https?://\S*\.digitaloceanspaces\.com/\S*', caseSensitive: false), '');
    
    // Clean up whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Decode common HTML entities
    sanitized = sanitized
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&ldquo;', '"')
      .replaceAll('&rdquo;', '"')
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rsquo;', "'")
      .replaceAll('&hellip;', '...')
      .replaceAll('&mdash;', '-')
      .replaceAll('&ndash;', '-');
    
    return sanitized.trim();
  }

  static Future<List<Article>> parseRssFeed(String feedUrl) async {
    if (!_isValidUrl(feedUrl)) {
      throw Exception('Invalid or unsafe URL: $feedUrl');
    }

    try {
      final response = await http.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent': 'PlusNews/1.0',
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final body = _decodeBody(response.bodyBytes);
      final document = XmlDocument.parse(body);
      final items = document.findAllElements('item');
      final source = _extractSource(document);

      return items.map((item) => _parseItem(item, source)).toList();
    } catch (e) {
      throw Exception('RSS parse error: $e');
    }
  }

  static String _decodeBody(List<int> bodyBytes) {
    try {
      return utf8.decode(bodyBytes);
    } catch (e) {
      return latin1.decode(bodyBytes);
    }
  }

  static String _extractSource(XmlDocument document) {
    final titleElement = document.findAllElements('title').firstOrNull;
    return titleElement?.text ?? 'Onbekende bron';
  }

  static Article _parseItem(XmlElement item, String source) {
    final title = _sanitizeHtml(_getElementText(item, 'title'));
    final description = _sanitizeHtml(_getElementText(item, 'description'));
    final link = _sanitizeUrl(_getElementText(item, 'link'));
    final pubDateStr = _getElementText(item, 'pubDate');
    final thumbnailUrl = _extractThumbnail(item);

    return Article(
      id: link.hashCode.toString(),
      title: title.isNotEmpty ? title : 'Geen titel',
      description: description,
      link: link,
      pubDate: _parseDate(pubDateStr),
      source: source,
      thumbnailUrl: _isValidUrl(thumbnailUrl) ? thumbnailUrl : null,
    );
  }

  static String _getElementText(XmlElement parent, String name) {
    final element = parent.findElements(name).firstOrNull;
    return element?.text ?? '';
  }

  static String? _extractThumbnail(XmlElement item) {
    // Try media:content
    final mediaContent = item.findElements('media:content').firstOrNull ??
                        item.findElements('content').firstOrNull;
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (_isValidUrl(url)) return url;
    }

    // Try enclosure
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      final type = enclosure.getAttribute('type') ?? '';
      if (type.startsWith('image/') && _isValidUrl(url)) return url;
    }

    // Try media:thumbnail
    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (_isValidUrl(url)) return url;
    }

    // Try to extract from description using simpler regex
    final description = _getElementText(item, 'description');
    final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(description);
    if (imgMatch != null) {
      final url = imgMatch.group(1);
      if (_isValidUrl(url)) return url;
    }

    return null;
  }

  static String _sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final sanitized = url.trim();
    return _isValidUrl(sanitized) ? sanitized : '';
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime(1970, 1, 1);
    }

    final formats = [
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})'),
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          if (match.groupCount >= 3) {
            final year = int.parse(match.group(3)!);
            final month = _parseMonth(match.group(2)!);
            final day = int.parse(match.group(1)!);
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime(1970, 1, 1);
    }
  }

  static int _parseMonth(String month) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[month] ?? 1;
  }
}
