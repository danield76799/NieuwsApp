import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/article.dart';
import '../utils/constants.dart';

/// Service voor het ophalen van nieuws via NewsAPI
class NewsApiService {
  final Dio _dio;
  late Box<dynamic> _cacheBox;
  
  NewsApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://newsapi.org/v2',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'X-Api-Key': Constants.newsApiKey,
    },
  )) {
    _initHive();
  }

  Future<void> _initHive() async {
    _cacheBox = await Hive.openBox('news_cache');
  }

  /// Haal top headlines op
  Future<List<Article>> getTopHeadlines({
    String country = 'nl',
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get('/top-headlines', queryParameters: {
        'country': country,
        if (category != null) 'category': category,
        'page': page,
        'pageSize': pageSize,
      });

      if (response.statusCode == 200) {
        final articles = (response.data['articles'] as List)
            .map((json) => Article.fromJson(json))
            .toList();
        
        // Cache de artikelen
        await _cacheArticles(articles);
        
        return articles;
      } else {
        throw Exception('Failed to load news: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Bij netwerk errors, probeer cache
      return _getCachedArticles();
    } catch (e) {
      return _getCachedArticles();
    }
  }

  /// Zoek nieuws op keywords
  Future<List<Article>> searchNews({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get('/everything', queryParameters: {
        'q': query,
        'language': 'nl',
        'sortBy': 'publishedAt',
        'page': page,
        'pageSize': pageSize,
      });

      if (response.statusCode == 200) {
        final articles = (response.data['articles'] as List)
            .map((json) => Article.fromJson(json))
            .toList();
        
        await _cacheArticles(articles);
        
        return articles;
      } else {
        throw Exception('Failed to search news: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      return _getCachedArticles();
    } catch (e) {
      return _getCachedArticles();
    }
  }

  /// Cache artikelen in Hive
  Future<void> _cacheArticles(List<Article> articles) async {
    final cacheData = articles.map((a) => a.toJson()).toList();
    await _cacheBox.put('cached_articles', jsonEncode(cacheData));
    await _cacheBox.put('cache_timestamp', DateTime.now().toIso8601String());
  }

  /// Haal gecachte artikelen op
  List<Article> _getCachedArticles() {
    try {
      final cachedData = _cacheBox.get('cached_articles');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => Article.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return [];
  }

  /// Check of cache nog geldig is (minder dan 1 uur oud)
  bool get isCacheValid {
    final timestamp = _cacheBox.get('cache_timestamp');
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.parse(timestamp);
    final difference = DateTime.now().difference(cacheTime);
    return difference.inHours < 1;
  }
}
