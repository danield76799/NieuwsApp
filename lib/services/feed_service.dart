import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedService {
  static const String _feedsKey = 'rss_feeds';
  
  // Default feeds - alleen werkende URLs met fallback
  static final List<Map<String, String>> _defaultFeeds = [
    {'name': 'Tweakers', 'url': 'https://tweakers.net/feeds/nieuws.xml'},
    {'name': 'NOS Nieuws', 'url': 'https://nos.nl/nieuws.rss'},
    {'name': 'Nu.nl', 'url': 'https://www.nu.nl/rss/Algemeen'},
    {'name': 'AD.nl', 'url': 'https://www.ad.nl/nieuws/rss.xml'},
  ];

  static Future<List<Map<String, String>>> getFeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_feedsKey);
      
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading feeds: $e');
    }
    
    // Return defaults if nothing saved
    return List.from(_defaultFeeds);
  }

  static Future<void> addFeed(String name, String url) async {
    try {
      final feeds = await getFeeds();
      feeds.add({'name': name, 'url': url});
      await _saveFeeds(feeds);
    } catch (e) {
      debugPrint('Error adding feed: $e');
    }
  }

  static Future<void> removeFeed(String url) async {
    try {
      final feeds = await getFeeds();
      feeds.removeWhere((feed) => feed['url'] == url);
      await _saveFeeds(feeds);
    } catch (e) {
      debugPrint('Error removing feed: $e');
    }
  }

  static Future<void> _saveFeeds(List<Map<String, String>> feeds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedsKey, jsonEncode(feeds));
  }
}
