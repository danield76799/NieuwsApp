import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/news_provider.dart';
import 'repositories/rss_news_repository.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  final repo = RssNewsRepository(storage);

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

  ThemeData _buildThemeData(ColorScheme colorScheme, bool isDark) {
    final ThemeData base = ThemeData.from(colorScheme: colorScheme);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.interTextTheme(
          ThemeData(colorScheme: colorScheme).textTheme,
        ).titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(colorScheme: colorScheme).textTheme,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ThemeData lightTheme = lightDynamic != null
            ? _buildThemeData(lightDynamic, false)
            : AppTheme.lightTheme;
        final ThemeData darkTheme = darkDynamic != null
            ? _buildThemeData(darkDynamic, true)
            : AppTheme.darkTheme;

        return MaterialApp(
          title: 'PlusNews',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        );
      },
    );
  }
}