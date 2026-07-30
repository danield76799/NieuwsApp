import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/time_helper.dart';
import '../screens/browser_reader_screen.dart';

class ArticleHeroCard extends StatefulWidget {
  final Article article;
  final double height;

  const ArticleHeroCard({
    super.key,
    required this.article,
    this.height = 220,
  });

  @override
  State<ArticleHeroCard> createState() => _ArticleHeroCardState();
}

class _ArticleHeroCardState extends State<ArticleHeroCard> {
  final _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() {
    setState(() {
      _isBookmarked = _bookmarkService.isBookmarked(widget.article.id);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.article);
    if (mounted) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    }
  }

  void _openArticle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserReaderScreen(article: widget.article),
      ),
    );
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.link}',
      subject: widget.article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // scale removed; using explicit TextStyles
    return GestureDetector(
      onTap: _openArticle,
      onLongPress: _shareArticle,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.article.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.article.imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      memCacheHeight: 300,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.article,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.article,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 48,
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.shadow.withValues(alpha: 0.1),
                      theme.colorScheme.shadow.withValues(alpha: 0.55),
                      theme.colorScheme.shadow.withValues(alpha: 0.8),
                    ],
                    stops: const [0.35, 0.55, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.article.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'NIEUW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    widget.article.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: 20,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        widget.article.source.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TimeHelper.format(widget.article.pubDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleBookmark,
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                      IconButton(
                        onPressed: _shareArticle,
                        icon: Icon(
                          Icons.share,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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

class ArticleCardV2 extends StatefulWidget {
  final Article article;

  const ArticleCardV2({super.key, required this.article});

  @override
  State<ArticleCardV2> createState() => _ArticleCardV2State();
}

class _ArticleCardV2State extends State<ArticleCardV2> {
  final _bookmarkService = BookmarkService();
  bool _isBookmarked = false;
  bool _isRead = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
    _checkRead();
  }

  void _checkBookmark() {
    setState(() {
      _isBookmarked = _bookmarkService.isBookmarked(widget.article.id);
    });
  }

  void _checkRead() {
    final readIds = BookmarkService().getReadArticleIds();
    setState(() {
      _isRead = readIds.contains(widget.article.id);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.article);
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  void _openArticle() {
    // Mark as read
    BookmarkService().markAsRead(widget.article.id);
    setState(() => _isRead = true);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserReaderScreen(article: widget.article),
      ),
    );
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.link}',
      subject: widget.article.title,
    );
  }

  String _readingTime() {
    final wordCount = '${widget.article.title} ${widget.article.description} ${widget.article.content ?? ''}'.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openArticle,
        onLongPress: _shareArticle,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isRead
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.article.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.article.thumbnailUrl!,
                        width: 100,
                        height: 75,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 150,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 75,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 75,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 75,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.article, color: theme.colorScheme.onSurfaceVariant),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isRead)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                          ),
                        Text(
                          widget.article.source.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TimeHelper.format(widget.article.pubDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.article.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _isRead ? FontWeight.w500 : FontWeight.w700,
                        height: 1.25,
                        color: _isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _readingTime(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _shareArticle,
                          icon: Icon(
                            Icons.share,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _toggleBookmark,
                          icon: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                            color: _isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                          padding: const EdgeInsets.all(4),
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
      ),
    );
  }
}
