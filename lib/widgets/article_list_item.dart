import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/time_helper.dart';
import '../screens/browser_reader_screen.dart';
import 'new_badge.dart';
import 'package:share_plus/share_plus.dart';

class ArticleListItem extends StatelessWidget {
  final Article article;

  const ArticleListItem({super.key, required this.article});

  void _openArticle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserReaderScreen(article: article),
      ),
    );
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${article.title}\n\n${article.link}',
      subject: article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // scale removed; using explicit TextStyles
    return InkWell(
      onTap: () => _openArticle(context),
      onLongPress: _shareArticle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: article.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: article.thumbnailUrl!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      placeholder: (context, url) => Container(
                        width: 84,
                        height: 84,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 84,
                        height: 84,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.article, color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (article.isNew) ...[
                        const SizedBox(width: 6),
                        const NewBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        TimeHelper.format(article.pubDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.source,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
