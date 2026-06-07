import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';

class BrowserReaderScreen extends StatefulWidget {
  final Article article;

  const BrowserReaderScreen({super.key, required this.article});

  @override
  State<BrowserReaderScreen> createState() => _BrowserReaderScreenState();
}

class _BrowserReaderScreenState extends State<BrowserReaderScreen> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  bool _isBookmarked = false;
  double _progress = 0;
  final _bookmarkService = BookmarkService();

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
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.link}',
      subject: widget.article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.source,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _shareArticle,
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') _controller.reload();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Herladen')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              color: Theme.of(context).colorScheme.primary,
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.article.link)),
              initialSettings: InAppWebViewSettings(
                supportZoom: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStart: (controller, url) => setState(() => _isLoading = true),
              onLoadStop: (controller, url) => setState(() => _isLoading = false),
              onProgressChanged: (controller, progress) => setState(() => _progress = progress / 100),
            ),
          ),
        ],
      ),
    );
  }
}
