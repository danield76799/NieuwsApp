import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/time_helper.dart';
import '../screens/article_webview_screen.dart';

// Helper function to strip HTML tags and ad URLs
String _stripHtml(String? text) {
  if (text == null || text.isEmpty) return '';
  
  // First remove all HTML tags (including multiline)
  var sanitized = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false, dotAll: true), '');
  
  // Remove common ad/tracking URLs and image references
  sanitized = sanitized
    .replaceAll(RegExp(r'https?://\S+\.(?:jpg|jpeg|png|gif|webp|svg)\S*', caseSensitive: false), '')
    .replaceAll(RegExp(r'https?://r\.testifier\.nl/\S*', caseSensitive: false), '')
    .replaceAll(RegExp(r'https?://\S*\.newsifier\.com/\S*', caseSensitive: false), '')
    .replaceAll(RegExp(r'https?://\S*\.digitaloceanspaces\.com/\S*', caseSensitive: false), '');
  
  // Clean up whitespace
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
  
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

class ArticleCardV2 extends StatefulWidget {
  final Article article;

  const ArticleCardV2({super.key, required this.article});

  @override
  State<ArticleCardV2> createState() => _ArticleCardV2State();
}

class _ArticleCardV2State extends State<ArticleCardV2> {
  final _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    await _bookmarkService.initialize();
    setState(() {
      _isBookmarked = _bookmarkService.isBookmarked(widget.article.id);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.article);
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.link}',
      subject: widget.article.title,
    );
  }

  void _openArticle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleWebViewScreen(article: widget.article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: _openArticle, // Directly open article on tap
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.article.thumbnailUrl!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              )
            else
              Container(
                height: 80,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.article, size: 32, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.article.source,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        TimeHelper.format(widget.article.pubDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.article.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stripHtml(widget.article.description),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _toggleBookmark,
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                          color: _isBookmarked ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                        tooltip: _isBookmarked ? 'Verwijder' : 'Bookmark',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _shareArticle,
                        icon: const Icon(Icons.share, size: 18),
                        color: Colors.grey,
                        tooltip: 'Delen',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}