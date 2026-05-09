/// App constants en configuratie
class Constants {
  // NewsAPI.org API key (gratis tier: 100 requests/day)
  // Haal je eigen key op via: https://newsapi.org/register
  // Demo key voor testen - vervang dit met je eigen key!
  static const String newsApiKey = 'demo';
  
  // App colors - NU.nl style
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color secondaryBlue = Color(0xFF1565C0);
  static const Color accentOrange = Color(0xFFFF9800);
  
  // API endpoints
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  static const String topHeadlinesEndpoint = '/top-headlines';
  static const String everythingEndpoint = '/everything';
  
  // Default settings
  static const String defaultCountry = 'nl';
  static const String defaultLanguage = 'nl';
  static const int defaultPageSize = 20;
  
  // Cache settings
  static const int cacheValidHours = 1;
  static const String cacheBoxName = 'news_cache';
  static const String settingsBoxName = 'news_settings';
  
  // Categories
  static const List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'Alles'},
    {'id': 'general', 'name': 'Algemeen'},
    {'id': 'business', 'name': 'Economie'},
    {'id': 'technology', 'name': 'Tech'},
    {'id': 'sports', 'name': 'Sport'},
    {'id': 'health', 'name': 'Gezondheid'},
    {'id': 'science', 'name': 'Wetenschap'},
    {'id': 'entertainment', 'name': 'Entertainment'},
  ];
  
  // Suggested keywords
  static const List<String> suggestedKeywords = [
    'AI',
    'Economie',
    'Sport',
    'Politiek',
    'Tech',
    'Gezondheid',
    'Klimaat',
    'Onderwijs',
    'Crypto',
    'Duurzaamheid',
  ];
}

class Color {
  final int value;
  
  const Color(this.value);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}