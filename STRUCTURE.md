# NieuwsApp - Flutter Nieuws App

## App Structuur

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp + theming
├── models/
│   └── article.dart          # Nieuws artikel model
├── services/
│   ├── news_api_service.dart # API calls naar nieuws.nl / NewsAPI
│   └── local_storage.dart    # Hive/SQLite voor offline opslag
├── providers/
│   └── news_provider.dart    # State management (Provider/Riverpod)
├── screens/
│   ├── home_screen.dart      # Hoofdscherm met artikelen lijst
│   ├── article_detail.dart   # Artikel detail pagina
│   └── settings_screen.dart  # Keyword filter instellingen
├── widgets/
│   ├── article_card.dart     # Artikel kaart widget (NU.nl style)
│   ├── news_badge.dart       # "Nieuw" label
│   └── filter_chip.dart      # Keyword filter chips
└── utils/
    └── constants.dart        # API keys, kleuren, etc.
```

## Technische Keuzes

- **State Management**: Provider (simpel, effectief)
- **HTTP Client**: Dio (met interceptors voor caching)
- **Local Storage**: Hive (snel, makkelijk, offline)
- **Image Caching**: CachedNetworkImage
- **API**: NewsAPI.org (gratis tier: 100 requests/day)

## Features

1. ✅ Artikelen ophalen via NewsAPI
2. ✅ Keyword filtering (AI, Economie, Sport, etc.)
3. ✅ Lokale opslag voor offline lezen
4. ✅ NU.nl design (witte achtergrond, blauwe header)
5. ✅ "Nieuw" badge voor artikelen < 1 uur oud
6. ✅ Thumbnail + titel + publicatietijd

## API Setup

NewsAPI.org gratis tier:
- 100 requests/day
- JSON response
- Filters: category, country, language

## Volgende Stap

Code schrijven voor:
1. Models (Article)
2. API Service
3. Local Storage
4. Provider (filter logic)
5. UI Screens
6. Widgets

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  provider: ^6.1.1
  cached_network_image: ^3.3.1
  intl: ^0.19.0
  url_launcher: ^6.2.5
  share_plus: ^7.2.2
```
