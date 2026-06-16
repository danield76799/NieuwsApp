import 'package:flutter/material.dart';
import '../models/article.dart';
import 'article_card.dart';

class NewsList extends StatelessWidget {
  final List<Article> articles;
  final Function(Article) onTap;

  const NewsList({super.key, required this.articles, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return ArticleCard(
          article: article,
          onTap: () => onTap(article),
        );
      },
    );
  }
}