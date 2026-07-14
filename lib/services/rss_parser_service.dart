import 'dart:async';
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
      // Retry logic voor 503 errors
      int retries = 2;
      while (retries >= 0) {
        try {
          final response = await http.get(
            Uri.parse(feedUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/rss+xml, application/xml, text/xml, */*',
              'Accept-Encoding': 'gzip, deflate',
              'Connection': 'keep-alive',
            },
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final body = _decodeBody(response.bodyBytes);
            final document = XmlDocument.parse(body);
            final items = document.findAllElements('item');
            final source = _extractSource(document);
            final channelImage = _extractChannelImage(document);

            return items.map((item) => _parseItem(item, source, channelImage)).toList();
          } else if (response.statusCode == 503 && retries > 0) {
            // Retry bij 503
            retries--;
            await Future.delayed(const Duration(seconds: 1));
            continue;
          } else {
            throw Exception('HTTP ${response.statusCode}');
          }
        } on TimeoutException {
          if (retries > 0) {
            retries--;
            continue;
          }
          throw Exception('Timeout');
        }
      }
      
      return [];
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
    // Try to get channel title first (usually the site name)
    final channelElement = document.findAllElements('channel').firstOrNull;
    if (channelElement != null) {
      final channelTitle = channelElement.findElements('title').firstOrNull?.value;
      if (channelTitle != null && channelTitle.isNotEmpty) {
        return _cleanSourceName(channelTitle);
      }
    }
    
    // Fallback to first title element
    final titleElement = document.findAllElements('title').firstOrNull;
    if (titleElement != null) {
      return _cleanSourceName(titleElement.value);
    }
    
    return 'Onbekende bron';
  }

  static String _cleanSourceName(String? name) {
    if (name == null || name.isEmpty) return 'Onbekende bron';
    
    // Remove common suffixes
    var cleaned = name
      .replaceAll(RegExp(r'\s*-\s*Nieuws$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*-\s*News$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*-\s*RSS$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*-\s*Feed$', caseSensitive: false), '')
      .trim();
    
    return cleaned.isNotEmpty ? cleaned : 'Onbekende bron';
  }

  static String? _extractChannelImage(XmlDocument document) {
    final imageElement = document.findAllElements('image').firstOrNull;
    if (imageElement != null) {
      final url = imageElement.findElements('url').firstOrNull?.value;
      if (_isValidUrl(url)) return url;
    }
    return null;
  }

  static Article _parseItem(XmlElement item, String source, String? channelImage) {
    final rawTitle = _getElementText(item, 'title');
    final rawDescription = _getElementText(item, 'description');
    final link = _sanitizeUrl(_getElementText(item, 'link'));
    final pubDateStr = _getElementText(item, 'pubDate');
    final thumbnailUrl = _extractThumbnail(item) ?? channelImage;

    // Sanitize once during parsing, not on every build
    final title = _sanitizeHtml(rawTitle);
    final description = _sanitizeHtml(rawDescription);

    return Article(
      id: link.hashCode.toString(),
      title: title.isNotEmpty ? title : 'Geen titel',
      description: description,
      link: link,
      pubDate: _parseDate(pubDateStr),
      source: source,
      thumbnailUrl: _isValidUrl(thumbnailUrl) ? thumbnailUrl : null,
      imageUrl: _isValidUrl(thumbnailUrl) ? thumbnailUrl : null,
    );
  }

  static String _getElementText(XmlElement parent, String name) {
    final element = parent.findElements(name).firstOrNull;
    return element?.value ?? '';
  }

  static String? _extractThumbnail(XmlElement item) {
    // Try media:content with medium="image"
    for (final mediaContent in item.findElements('media:content')) {
      final url = mediaContent.getAttribute('url');
      final medium = mediaContent.getAttribute('medium') ?? '';
      if (medium == 'image' && _isValidUrl(url)) return url;
    }

    // Try media:group -> media:content
    final mediaGroup = item.findElements('media:group').firstOrNull;
    if (mediaGroup != null) {
      for (final mediaContent in mediaGroup.findElements('media:content')) {
        final url = mediaContent.getAttribute('url');
        final medium = mediaContent.getAttribute('medium') ?? '';
        final type = mediaContent.getAttribute('type') ?? '';
        if ((medium == 'image' || type.startsWith('image/')) && _isValidUrl(url)) return url;
      }
      // Also try media:thumbnail inside media:group
      final thumb = mediaGroup.findElements('media:thumbnail').firstOrNull;
      if (thumb != null) {
        final url = thumb.getAttribute('url');
        if (_isValidUrl(url)) return url;
      }
    }

    // Try media:content (any)
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

    // Try itunes:image
    final itunesImage = item.findElements('itunes:image').firstOrNull;
    if (itunesImage != null) {
      final url = itunesImage.getAttribute('href');
      if (_isValidUrl(url)) return url;
    }

    // Try image tag inside item
    final imageTag = item.findElements('image').firstOrNull;
    if (imageTag != null) {
      final url = imageTag.findElements('url').firstOrNull?.value;
      if (_isValidUrl(url)) return url;
    }

    // Try to extract from description/content using regex
    final description = _getElementText(item, 'description');
    final content = _getElementText(item, 'content:encoded');
    final combined = '$description $content';

    // Match img src
    final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(combined);
    if (imgMatch != null) {
      final url = imgMatch.group(1);
      if (_isValidUrl(url)) return url;
    }

    // Match data-src (lazy loading)
    final dataSrcMatch = RegExp(r'data-src="([^"]+)"').firstMatch(combined);
    if (dataSrcMatch != null) {
      final url = dataSrcMatch.group(1);
      if (_isValidUrl(url)) return url;
    }

    // Match og:image or twitter:image meta
    final ogMatch = RegExp(r'property="og:image"[^>]+content="([^"]+)"').firstMatch(combined);
    if (ogMatch != null) {
      final url = ogMatch.group(1);
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
      return DateTime.now(); // Use current time instead of 1970
    }

    // RSS standard format: Sun, 10 May 2026 10:01:23 +0200
    final rfc822Regex = RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})'
    );
    final rfc822Match = rfc822Regex.firstMatch(dateStr);
    if (rfc822Match != null) {
      try {
        final day = int.parse(rfc822Match.group(1)!);
        final month = _parseMonth(rfc822Match.group(2)!);
        final year = int.parse(rfc822Match.group(3)!);
        final hour = int.parse(rfc822Match.group(4)!);
        final minute = int.parse(rfc822Match.group(5)!);
        final second = int.parse(rfc822Match.group(6)!);
        return DateTime(year, month, day, hour, minute, second);
      } catch (e) {
        // Fall through to other parsers
      }
    }

    // ISO format: 2026-05-10T10:01:23+02:00
    final isoRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2}):(\d{2})');
    final isoMatch = isoRegex.firstMatch(dateStr);
    if (isoMatch != null) {
      try {
        final year = int.parse(isoMatch.group(1)!);
        final month = int.parse(isoMatch.group(2)!);
        final day = int.parse(isoMatch.group(3)!);
        final hour = int.parse(isoMatch.group(4)!);
        final minute = int.parse(isoMatch.group(5)!);
        final second = int.parse(isoMatch.group(6)!);
        return DateTime(year, month, day, hour, minute, second);
      } catch (e) {
        // Fall through
      }
    }

    // Simple date format: 2026-05-10
    final simpleDateRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    final simpleMatch = simpleDateRegex.firstMatch(dateStr);
    if (simpleMatch != null) {
      try {
        final year = int.parse(simpleMatch.group(1)!);
        final month = int.parse(simpleMatch.group(2)!);
        final day = int.parse(simpleMatch.group(3)!);
        return DateTime(year, month, day);
      } catch (e) {
        // Fall through
      }
    }

    // Try standard DateTime.parse as fallback
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now(); // Fallback to current time instead of 1970
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
