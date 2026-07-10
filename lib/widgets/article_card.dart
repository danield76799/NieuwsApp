import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../widgets/news_badge.dart';
import '../screens/browser_reader_screen.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final bool showBookmarkButton;
  final VoidCallback? onBookmarkRemoved;

  const ArticleCard({
    super.key,
    required this.article,
    this.showBookmarkButton = false,
    this.onBookmarkRemoved,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
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
    
    if (widget.onBookmarkRemoved != null && !_isBookmarked) {
      widget.onBookmarkRemoved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => _openArticle(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _buildThumbnail(theme),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source + time row
                    Row(
                      children: [
                        Text(
                          widget.article.source,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.article.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        // Nieuw badge
                        if (widget.article.isNew) ...[
                          const SizedBox(width: 8),
                          const NewsBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Title
                    Text(
                      widget.article.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                  // Description - More visible, better styling
                    if (widget.article.description.isNotEmpty)
                      Text(
                        widget.article.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Bookmark button
                    if (widget.showBookmarkButton)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: _isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    if (widget.article.imageUrl == null || widget.article.imageUrl!.isEmpty) {
      return Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: widget.article.imageUrl!,
        width: 120,
        height: 100,
        fit: BoxFit.cover,
        memCacheWidth: 240, // 2x voor retina
        memCacheHeight: 200,
        maxWidthDiskCache: 480,
        maxHeightDiskCache: 400,
        placeholder: (context, url) => Container(
          width: 120,
          height: 100,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 120,
          height: 100,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _openArticle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserReaderScreen(article: widget.article),
      ),
    );
  }

  void _shareArticle() {
    final url = widget.article.url ?? widget.article.link;
    Share.share(
      '${widget.article.title}\n\n$url',
      subject: widget.article.title,
    );
  }
}
