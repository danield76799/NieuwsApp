import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedService {
  static const String _feedsKey = 'rss_feeds';
  
  // Default feeds - alleen werkende URLs (geverifieerd 2026-07-24)
  static final List<Map<String, String>> _defaultFeeds = [
    {'name': 'Tweakers', 'url': 'https://tweakers.net/feeds/nieuws.xml'},
    {'name': 'NOS Nieuws', 'url': 'https://feeds.nos.nl/nosnieuwsalgemeen'},
    {'name': 'Nu.nl', 'url': 'https://www.nu.nl/rss/Algemeen'},
    {'name': 'AD.nl', 'url': 'https://www.ad.nl/nieuws/rss.xml'},
    {'name': 'Volkskrant', 'url': 'https://www.volkskrant.nl/rss.xml'},
  ];

  /// Merge saved feeds with the defaults so a user who once added a single
  /// custom feed does not lose the built-in sources. Defaults that are
  /// already present (by URL) are not duplicated.
  static Future<List<Map<String, String>>> getFeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_feedsKey);

      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(data);
        final saved = jsonList.map((e) => Map<String, String>.from(e)).toList();
        // If the saved list is missing any default, append the missing ones.
        // This keeps user-added feeds while guaranteeing the default sources
        // are always available.
        final savedUrls = saved.map((f) => f['url']).toSet();
        final merged = List<Map<String, String>>.from(saved);
        for (final def in _defaultFeeds) {
          if (!savedUrls.contains(def['url'])) {
            merged.add(def);
          }
        }
        // Persist the merge so it only happens once.
        await _saveFeeds(merged);
        return merged;
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
