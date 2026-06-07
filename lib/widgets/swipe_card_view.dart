import 'dart:math';
import 'package:flutter/material.dart';
import '../models/article.dart';
import 'article_card_v2.dart';

class SwipeCardView extends StatefulWidget {
  final List<Article> articles;

  const SwipeCardView({super.key, required this.articles});

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

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.articles.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final article = widget.articles[index];
              final offset = (index - _currentPage).abs().toDouble();
              final scale = max(0.85, 1.0 - offset * 0.15);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08 + offset * 0.05),
                      blurRadius: 8 + offset * 8,
                      offset: Offset(0, 4 + offset * 4),
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  child: ArticleHeroCard(article: article),
                ),
              );
            },
          ),
        ),
        // Page dots
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
