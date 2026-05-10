import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
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
        return {
          'location': city,
          'temp': data['current_condition'][0]['temp_C'],
          'feelsLike': data['current_condition'][0]['FeelsLikeC'],
          'description': data['current_condition'][0]['weatherDesc'][0]['value'],
          'icon': data['current_condition'][0]['weatherIconUrl'][0]['value'],
          'humidity': data['current_condition'][0]['humidity'],
          'wind': data['current_condition'][0]['windspeedKmph'],
          'forecast': data['weather'].take(3).map((day) => {
            'date': day['date'],
            'maxTemp': day['maxtempC'],
            'minTemp': day['mintempC'],
            'description': day['hourly'][4]['weatherDesc'][0]['value'],
          }).toList(),
        };
      }
    } catch (e) {
      print('WeatherService: Weather error for $city: $e');
    }
    return null;
  }
}