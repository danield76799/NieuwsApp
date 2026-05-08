# NieuwsApp - Flutter Nieuws App

Een mobiele nieuws-app gebouwd met Flutter die lijkt op de NU.nl app.

## Features

✅ **Nieuws ophalen** via NewsAPI.org (top headlines Nederland)
✅ **Keyword filtering** - Filter artikelen op keywords (AI, Economie, Sport, etc.)
✅ **Offline opslag** - Artikelen worden lokaal opgeslagen via Hive
✅ **NU.nl design** - Witte achtergrond, blauwe header, clean interface
✅ **"Nieuw" badge** - Artikelen < 1 uur oud krijgen een badge
✅ **Thumbnail + titel + tijd** - Net als NU.nl
✅ **Categorieën** - Algemeen, Economie, Tech, Sport, Gezondheid, etc.
✅ **Zoeken** - Zoek door alle nieuwsartikelen
✅ **Delen** - Deel artikelen via andere apps

## Screenshots

| Home | Artikel | Instellingen |
|------|---------|--------------|
| Lijst met artikelen | Detail view | Keyword filters |

## Structuur

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp + theming
├── models/
│   └── article.dart       # Artikel model
├── services/
│   └── news_api_service.dart  # API calls + caching
├── providers/
│   └── news_provider.dart     # State management
├── screens/
│   ├── home_screen.dart       # Hoofdscherm
│   └── settings_screen.dart   # Keyword filters
├── widgets/
│   ├── article_card.dart      # Artikel kaart (NU.nl style)
│   └── news_badge.dart        # "Nieuw" label
└── utils/
    └── constants.dart         # Configuratie
```

## Technische Details

### State Management
- **Provider** - Simpel en effectief voor deze app

### HTTP Client
- **Dio** - Met interceptors voor error handling en caching

### Local Storage
- **Hive** - Snelle NoSQL database voor offline opslag

### Image Caching
- **CachedNetworkImage** - Afbeeldingen cachen voor snellere laadtijden

### Dependencies
```yaml
dependencies:
  dio: ^5.4.0                    # HTTP client
  hive: ^2.2.3                   # Local storage
  hive_flutter: ^1.1.0           # Hive Flutter integratie
  provider: ^6.1.1               # State management
  cached_network_image: ^3.3.1   # Image caching
  intl: ^0.19.0                  # Datum formatting
  url_launcher: ^6.2.5           # Open links in browser
  share_plus: ^7.2.2             # Delen van artikelen
  shimmer: ^3.0.0                # Loading shimmer effect
```

## Setup

### 1. API Key verkrijgen
1. Ga naar [NewsAPI.org](https://newsapi.org/register)
2. Registreer voor een gratis account (100 requests/day)
3. Kopieer je API key

### 2. API Key toevoegen
Open `lib/utils/constants.dart` en vervang:
```dart
static const String newsApiKey = 'YOUR_API_KEY_HERE';
```

### 3. Dependencies installeren
```bash
flutter pub get
```

### 4. App starten
```bash
flutter run
```

## Keyword Filter Functionaliteit

### Hoe het werkt:
1. Ga naar **Instellingen** (tandwiel icoon)
2. Voeg keywords toe zoals "AI", "Economie", "Sport"
3. Artikelen worden gefilterd op basis van deze keywords
4. Alleen artikelen die deze woorden bevatten worden getoond

### Voorbeeld:
- Keyword: "AI" → Toont alleen artikelen over AI
- Keywords: "AI, Tech" → Toont artikelen over AI of Tech
- Geen keywords → Toont alle artikelen

## Offline Functionaliteit

Artikelen worden automatisch lokaal opgeslagen:
- Bij eerste load worden artikelen gecached
- Bij geen internet worden gecachte artikelen getoond
- Cache is 1 uur geldig

## Design - NU.nl Style

- **Kleuren**: Witte achtergrond, blauwe header (#1E88E5)
- **Kaarten**: Wit met lichte border, afgeronde hoeken
- **Typografie**: Roboto font, vette titels, grijze beschrijving
- **Layout**: Thumbnail links, titel + tijd rechts
- **Badge**: Blauw "NIEUW" label voor recente artikelen

## Volgende Stappen / TODO

- [ ] Push notificaties voor breaking news
- [ ] Donker thema
- [ ] Bookmark artikelen
- [ ] Meer nieuwsbronnen toevoegen
- [ ] Infinite scroll pagination
- [ ] Animaties en transitions

## Licentie

MIT License - Vrij te gebruiken en aan te passen.

## Credits

- Nieuws data: [NewsAPI.org](https://newsapi.org)
- Design geïnspireerd door: [NU.nl](https://nu.nl)
