import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/news_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'repositories/rss_news_repository.dart';
import 'screens/home_screen.dart';
import 'services/bookmark_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = RssNewsRepository();

  // Pre-initialize bookmark service for performance
  await BookmarkService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = NewsProvider(repo);
            provider.loadNews();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ],
      child: const PlusNewsApp(),
    ),
  );
}

class PlusNewsApp extends StatelessWidget {
  const PlusNewsApp({super.key});

  ThemeData _buildThemeData(ColorScheme colorScheme, bool isDark) {
    final ThemeData base = ThemeData.from(colorScheme: colorScheme);

    // Consistent botanical typography (Lora headings + Inter body),
    // applied whether or not dynamic color is active.
    final onSurface = colorScheme.onSurface;
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme.copyWith(
        displayLarge: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface),
        headlineMedium: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
        titleLarge: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : null,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: textTheme,
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

        return Consumer<ThemeModeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'PlusNews',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
