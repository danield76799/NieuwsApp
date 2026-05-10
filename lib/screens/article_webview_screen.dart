import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';

class ArticleWebViewScreen extends StatefulWidget {
  final Article article;

  const ArticleWebViewScreen({super.key, required this.article});

  @override
  State<ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<ArticleWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isBookmarked = false;
  final _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _checkBookmark();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.link));
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
              color: _isBookmarked ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: _isBookmarked ? 'Verwijder bookmark' : 'Bookmark',
          ),
          IconButton(
            onPressed: _shareArticle,
            icon: const Icon(Icons.share),
            tooltip: 'Delen',
          ),
          IconButton(
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              }
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Terug',
          ),
          IconButton(
            onPressed: () async {
              if (await _controller.canGoForward()) {
                await _controller.goForward();
              }
            },
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Vooruit',
          ),
          IconButton(
            onPressed: () {
              _controller.reload();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Herladen',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
