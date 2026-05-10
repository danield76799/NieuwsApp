import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // Vertaaltabel voor weersomstandigheden
  static final Map<String, String> _weatherTranslations = {
    'Sunny': 'Zonnig',
    'Clear': 'Helder',
    'Partly cloudy': 'Deels bewolkt',
    'Cloudy': 'Bewolkt',
    'Overcast': 'Zwaar bewolkt',
    'Mist': 'Mistig',
    'Patchy rain possible': 'Plaatselijke regen mogelijk',
    'Patchy snow possible': 'Plaatselijke sneeuw mogelijk',
    'Patchy sleet possible': 'Plaatselijke ijzel mogelijk',
    'Patchy freezing drizzle possible': 'Plaatselijke motregen mogelijk',
    'Thundery outbreaks possible': 'Onweer mogelijk',
    'Blowing snow': 'Stuifsneeuw',
    'Blizzard': 'Sneeuwstorm',
    'Fog': 'Mist',
    'Freezing fog': 'IJsmist',
    'Patchy light drizzle': 'Plaatselijke lichte motregen',
    'Light drizzle': 'Lichte motregen',
    'Freezing drizzle': 'IJzel',
    'Heavy freezing drizzle': 'Zware ijzel',
    'Patchy light rain': 'Plaatselijke lichte regen',
    'Light rain': 'Lichte regen',
    'Moderate rain at times': 'Af en toe matige regen',
    'Moderate rain': 'Matige regen',
    'Heavy rain at times': 'Af en toe zware regen',
    'Heavy rain': 'Zware regen',
    'Light freezing rain': 'Lichte ijzelregen',
    'Moderate or heavy freezing rain': 'Matige of zware ijzelregen',
    'Light sleet': 'Lichte ijzel',
    'Moderate or heavy sleet': 'Matige of zware ijzel',
    'Patchy light snow': 'Plaatselijke lichte sneeuw',
    'Light snow': 'Lichte sneeuw',
    'Patchy moderate snow': 'Plaatselijke matige sneeuw',
    'Moderate snow': 'Matige sneeuw',
    'Patchy heavy snow': 'Plaatselijke zware sneeuw',
    'Heavy snow': 'Zware sneeuw',
    'Ice pellets': 'Hagel',
    'Light rain shower': 'Lichte regenbui',
    'Moderate or heavy rain shower': 'Matige of zware regenbui',
    'Torrential rain shower': 'Stortregen',
    'Light sleet showers': 'Lichte ijzelbuien',
    'Moderate or heavy sleet showers': 'Matige of zware ijzelbuien',
    'Light snow showers': 'Lichte sneeuwbuien',
    'Moderate or heavy snow showers': 'Matige of zware sneeuwbuien',
    'Light showers of ice pellets': 'Lichte hagelbuien',
    'Moderate or heavy showers of ice pellets': 'Matige of zware hagelbuien',
    'Patchy light rain with thunder': 'Plaatselijke lichte regen met onweer',
    'Moderate or heavy rain with thunder': 'Matige of zware regen met onweer',
    'Patchy light snow with thunder': 'Plaatselijke lichte sneeuw met onweer',
    'Moderate or heavy snow with thunder': 'Matige of zware sneeuw met onweer',
  };

  static String translateWeather(String english) {
    return _weatherTranslations[english] ?? english;
  }

  static IconData getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('sun') || desc.contains('clear')) return Icons.wb_sunny;
    if (desc.contains('cloud') || desc.contains('overcast')) return Icons.wb_cloudy;
    if (desc.contains('rain') || desc.contains('drizzle')) return Icons.water_drop;
    if (desc.contains('snow') || desc.contains('sleet') || desc.contains('blizzard')) return Icons.ac_unit;
    if (desc.contains('thunder') || desc.contains('storm')) return Icons.thunderstorm;
    if (desc.contains('mist') || desc.contains('fog')) return Icons.foggy;
    return Icons.wb_sunny;
  }

  static Future<Map<String, dynamic>?> getWeatherForCity(String city) async {
    try {
      print('WeatherService: Fetching weather for $city');
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
        headers: {'User-Agent': 'PlusNews/1.0'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('WeatherService: Got weather for $city');
        
        // Haal de echte locatie naam op uit de API response
        final locationName = data['nearest_area']?[0]?['areaName']?[0]?['value'] ?? city;
        
        return {
          'location': locationName,
          'temp': data['current_condition'][0]['temp_C'],
          'feelsLike': data['current_condition'][0]['FeelsLikeC'],
          'description': translateWeather(data['current_condition'][0]['weatherDesc'][0]['value']),
          'icon': data['current_condition'][0]['weatherIconUrl'][0]['value'],
          'humidity': data['current_condition'][0]['humidity'],
          'wind': data['current_condition'][0]['windspeedKmph'],
          'forecast': data['weather'].take(3).map((day) => {
            'date': day['date'],
            'maxTemp': day['maxtempC'],
            'minTemp': day['mintempC'],
            'description': translateWeather(day['hourly'][4]['weatherDesc'][0]['value']),
            'icon': getWeatherIcon(day['hourly'][4]['weatherDesc'][0]['value']),
          }).toList(),
        };
      }
    } catch (e) {
      print('WeatherService: Weather error for $city: $e');
    }
    return null;
  }
}