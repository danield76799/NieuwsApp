import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/news_provider.dart';
import 'repositories/rss_news_repository.dart';
import 'screens/home_screen.dart';
import 'services/rss_parser_service.dart';
import 'services/storage_service.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF007BC7),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007BC7),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}