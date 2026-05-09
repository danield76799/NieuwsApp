import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/news_provider.dart';
import 'repositories/rss_news_repository.dart';
import 'screens/home_screen.dart';
import 'services/rss_parser_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = StorageService();
  final rss = RssParserService();
  final repo = RssNewsRepository(rss, storage);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = NewsProvider(repo);
        provider.loadNews();
        return provider;
      },
      child: const PlusNewsApp(),
    ),
  );
}

class PlusNewsApp extends StatelessWidget {
  const PlusNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlusNews',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
