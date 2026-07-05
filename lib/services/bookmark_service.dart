import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  bool _isInitialized = false;
  List<Article> _bookmarks = [];

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadBookmarks();
    _isInitialized = true;
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('bookmarks');
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _bookmarks = jsonList.map((json) => Article.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      _bookmarks = [];
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _bookmarks.map((a) => a.toJson()).toList();
      await prefs.setString('bookmarks', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> addBookmark(Article article) async {
    await _ensureInitialized();
    if (!_bookmarks.any((b) => b.id == article.id)) {
      _bookmarks.add(article);
      await _saveBookmarks();
    }
  }

  Future<void> removeBookmark(String articleId) async {
    await _ensureInitialized();
    _bookmarks.removeWhere((b) => b.id == articleId);
    await _saveBookmarks();
  }

  bool isBookmarked(String articleId) {
    if (!_isInitialized) return false;
    return _bookmarks.any((b) => b.id == articleId);
  }

  Future<void> toggleBookmark(Article article) async {
    if (isBookmarked(article.id)) {
      await removeBookmark(article.id);
    } else {
      await addBookmark(article);
    }
  }

  List<Article> getBookmarks() {
    if (!_isInitialized) return [];
    return List.from(_bookmarks);
  }

  Future<void> clearAll() async {
    await _ensureInitialized();
    _bookmarks = [];
    await _saveBookmarks();
  }

  int get bookmarkCount => _bookmarks.length;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
