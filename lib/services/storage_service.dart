import 'package:hive/hive.dart';
import '../models/article.dart';

class StorageService {
  static const String _boxName = 'articles';
  Box<Article>? _box;

  Future<Box<Article>> _getBox() async {
    _box ??= await Hive.openBox<Article>(_boxName);
    return _box!;
  }

  Future<void> cacheArticles(List<Article> articles) async {
    final box = await _getBox();
    await box.clear();
    for (final article in articles) {
      await box.put(article.id, article);
    }
  }

  Future<List<Article>> getCachedArticles() async {
    final box = await _getBox();
    return box.values.toList();
  }
}