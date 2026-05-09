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
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        List<Article> articles = [];
        
        for (var item in items) {
          final title = item.findElements('title').firstOrNull?.text ?? '';
          final link = item.findElements('link').firstOrNull?.text ?? '';
          final description = item.findElements('description').firstOrNull?.text ?? '';
          final pubDate = item.findElements('pubDate').firstOrNull?.text ?? '';
          final enclosure = item.findElements('enclosure').firstOrNull;
          
          String? thumbnailUrl;
          if (enclosure != null) {
            thumbnailUrl = enclosure.getAttribute('url');
          }
          
          String articleCategory = 'algemeen';
          final categoryMatch = RegExp(r'https?://[^/]+/([^/]+)/').firstMatch(link);
          if (categoryMatch != null) {
            articleCategory = categoryMatch.group(1) ?? 'algemeen';
          }
          
          articles.add(Article(
            id: link.hashCode.toString(),
            title: _cleanText(title),
            description: _cleanText(description),
            link: link,
            pubDate: _parseDate(pubDate),
            thumbnailUrl: thumbnailUrl,
            source: sourceName,
            category: articleCategory,
          ));
        }
        
        return articles;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('RSS parse error: $e');
    }
  }
  
  String _cleanText(String html) {
    var text = html.replaceAll(RegExp(r'<\!\[CDATA\[(.*?)\]\]>'), r'$1');
    text = text.replaceAll(RegExp(r'<img[^>]*>'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&#039;', "'").replaceAll('&nbsp;', ' ');
    text = text.trim();
    if (text.length > 300) {
      text = text.substring(0, 300) + '...';
    }
    return text;
  }
  
  DateTime _parseDate(String rssDate) {
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
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }
}