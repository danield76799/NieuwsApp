import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../services/article_cache_service.dart';
import '../services/rss_parser_service.dart';
import "news_repository.dart";

class RssNewsRepository implements NewsRepository {
  RssNewsRepository();

  @override
  Future<List<Article>> fetchNews({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt('last_fetch_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (forceRefresh || (now - lastFetchTime) > 900000) {
        final articles = await _fetchNewsFromSources();
        await prefs.setInt('last_fetch_time', now);
        return articles;
      } else {
        final cachedArticles = await ArticleCacheService.getCachedArticles();
        return cachedArticles ?? [];
      }
    } catch (e) {
      print('Error fetching news: $e');
      final cachedArticles = await ArticleCacheService.getCachedArticles();
      return cachedArticles ?? [];
    }
  }

  @override
  List<Article> filterByKeywords(List<Article> articles, List<String> keywords) {
    if (keywords.isEmpty) return articles;

    final lowerKeywords = keywords.map((k) => k.toLowerCase().trim()).toList();

    return articles.where((article) {
      final searchText = "${article.title} ${article.description}".toLowerCase();
      return lowerKeywords.any((keyword) => searchText.contains(keyword));
    }).toList();
  }

  @override
  Future<List<Article>> fetchNewsWithFilter(List<String> keywords) async {
    final articles = await _fetchNewsFromSources();
    return filterByKeywords(articles, keywords);
  }

  Future<List<Article>> _fetchNewsFromSources() async {
    final articles = <Article>[];
    final sources = [
      'https://www.nrc.nl/nieuws/rss',
      'https://www.volkskrant.nl/rss/nieuws',
      'https://www.trouw.nl/rss/nieuws',
      'https://nos.nl/rss/nieuws',
      'https://www.ad.nl/rss/nieuws',
    ];

    await Future.wait(sources.map((source) async {
      try {
        final response = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final parsedArticles = await RssParserService.parseRssFeed(response.body);
          articles.addAll(parsedArticles);
        }
      } catch (e) {
        print('Error fetching from $source: $e');
      }
    }));

    // Remove duplicates
    final uniqueArticles = <Article>{};
    for (final article in articles) {
      uniqueArticles.add(article);
    }

    // Sort by date (newest first)
    return uniqueArticles.toList()..sort((a, b) => b.pubDate.compareTo(a.pubDate));
  }
}
