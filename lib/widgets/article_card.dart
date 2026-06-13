import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/article_cache_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/news_badge.dart';
import '../screens/cached_article_reader_screen.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF242424), // Dark card surface
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
              _buildThumbnail(),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE60000), // NOS red for source
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.article.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                          color: Colors.grey[400],
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
                            color: _isBookmarked ? const Color(0xFF1E88E5) : Colors.grey,
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

  Widget _buildThumbnail() {
    if (widget.article.imageUrl == null || widget.article.imageUrl!.isEmpty) {
      return Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[600],
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
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE60000),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 120,
          height: 100,
          color: Colors.grey[800],
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[600],
            size: 32,
          ),
        ),
      ),
    );
  }

  void _openArticle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Source + time
                Row(
                  children: [
                    Text(
                      widget.article.source,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE60000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.article.formattedTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  widget.article.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Image
                if (widget.article.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.article.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Content
                Text(
                  widget.article.content?.isNotEmpty == true 
                      ? widget.article.content! 
                      : widget.article.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Lees volledig artikel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE60000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _shareArticle(),
                      icon: const Icon(Icons.share),
                      color: const Color(0xFFE60000),
                    ),
                    IconButton(
                      onPressed: _toggleBookmark,
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      color: _isBookmarked ? const Color(0xFFE60000) : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl() async {
    final url = widget.article.url ?? widget.article.link;
    final cachedContent = await ArticleCacheService.getArticleContent(widget.article.id);
    if (cachedContent != null && cachedContent.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CachedArticleReaderScreen(
            title: widget.article.title,
            content: cachedContent,
            source: widget.article.source,
            pubDate: widget.article.pubDate,
          ),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareArticle() {
    final url = widget.article.url ?? widget.article.link;
    Share.share(
      '${widget.article.title}\n\n$url',
      subject: widget.article.title,
    );
  }
}