import 'dart:math';
import 'package:flutter/material.dart';
import '../models/article.dart';
import 'article_card_v2.dart';

class SwipeCardView extends StatefulWidget {
  final List<Article> articles;
  final Future<void> Function() onRefresh;

  const SwipeCardView({
    super.key,
    required this.articles,
    required this.onRefresh,
  });

  @override
  State<SwipeCardView> createState() => _SwipeCardViewState();
}

class _SwipeCardViewState extends State<SwipeCardView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return const Center(child: Text('Geen artikelen'));
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      displacement: 50,
      edgeOffset: 8,
      strokeWidth: 3,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chip
          if (widget.articles.length > 10)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Center(
                  child: Text(
                    '${widget.articles.length} artikelen',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Swipe cards: verticale pull-to-refresh via CustomScrollView,
          // horizontale swipe via PageView in SliverFillRemaining.
          SliverFillRemaining(
            hasScrollBody: false,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.articles.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final article = widget.articles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ArticleHeroCard(article: article),
                );
              },
            ),
          ),

          // Page dots
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  min(widget.articles.length, 10),
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
