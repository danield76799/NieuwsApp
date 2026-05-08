import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/article.dart';

/// Service voor het beheren van bookmarks
class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  late Box<dynamic> _bookmarksBox;
  bool _isInitialized = false;

  /// Initialize Hive box
  Future<void> initialize() async {
    if (_isInitialized) return;
    _bookmarksBox = await Hive.openBox('bookmarks');
    _isInitialized = true;
  }

  /// Voeg artikel toe aan bookmarks
  Future<void> addBookmark(Article article) async {
    await _ensureInitialized();
    final bookmarks = getBookmarks();
    
    // Check of artikel al bestaat
    if (!bookmarks.any((b) => b.id == article.id)) {
      bookmarks.add(article);
      await _saveBookmarks(bookmarks);
    }
  }

  /// Verwijder artikel uit bookmarks
  Future<void> removeBookmark(String articleId) async {
    await _ensureInitialized();
    final bookmarks = getBookmarks();
    bookmarks.removeWhere((b) => b.id == articleId);
    await _saveBookmarks(bookmarks);
  }

  /// Check of artikel is gebookmarkt
  bool isBookmarked(String articleId) {
    if (!_isInitialized) return false;
    final bookmarks = getBookmarks();
    return bookmarks.any((b) => b.id == articleId);
  }

  /// Toggle bookmark status
  Future<void> toggleBookmark(Article article) async {
    if (isBookmarked(article.id)) {
      await removeBookmark(article.id);
    } else {
      await addBookmark(article);
    }
  }

  /// Haal alle bookmarks op
  List<Article> getBookmarks() {
    if (!_isInitialized) return [];
    
    final data = _bookmarksBox.get('articles');
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Article.fromJson(json)).toList();
    } catch (e) {
      print('Error loading bookmarks: $e');
      return [];
    }
  }

  /// Sla bookmarks op
  Future<void> _saveBookmarks(List<Article> bookmarks) async {
    final jsonList = bookmarks.map((a) => a.toJson()).toList();
    await _bookmarksBox.put('articles', jsonEncode(jsonList));
  }

  /// Wis alle bookmarks
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _bookmarksBox.delete('articles');
  }

  /// Aantal bookmarks
  int get bookmarkCount => getBookmarks().length;

  /// Ensure initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}