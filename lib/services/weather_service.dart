import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static Future<Map<String, dynamic>?> getWeatherForLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('WeatherService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('WeatherService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('WeatherService: After request: $permission');
        if (permission == LocationPermission.denied) {
          print('WeatherService: Permission denied, using Amsterdam');
          return getWeather('Amsterdam');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('WeatherService: Permission denied forever, using Amsterdam');
        return getWeather('Amsterdam');
      }

      // Try to get current position with shorter timeout
      Position? position;
      try {
        print('WeatherService: Getting current position...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Use low accuracy for speed
        ).timeout(Duration(seconds: 8));
        print('WeatherService: Got position: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('WeatherService: Error getting position: $e');
        // Try last known position immediately
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          print('WeatherService: Using last known position: ${position.latitude}, ${position.longitude}');
        } else {
          print('WeatherService: No last known position available');
        }
      }
      
      if (position == null) {
        print('WeatherService: No position available, using Amsterdam');
        return getWeather('Amsterdam');
      }
      
      // Use coordinates for weather
      final lat = position.latitude.toStringAsFixed(4);
      final lon = position.longitude.toStringAsFixed(4);
      
      print('WeatherService: Fetching weather for: $lat, $lon');
      
      final response = await http.get(
        Uri.parse('https://wttr.in/$lat,$lon?format=j1'),
        headers: {'User-Agent': 'PlusNews/1.0'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Try to get location name from various sources
        String location = 'Huidige locatie';
        try {
          if (data['nearest_area'] != null && data['nearest_area'].isNotEmpty) {
            final area = data['nearest_area'][0];
            if (area['areaName'] != null && area['areaName'].isNotEmpty) {
              location = area['areaName'][0]['value'] ?? location;
            }
          }
        } catch (e) {
          print('WeatherService: Error parsing location name: $e');
        }
        
        print('WeatherService: Weather location: $location');
        
        return {
          'location': location,
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
      } else {
        print('WeatherService: Weather API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('WeatherService: Location weather error: $e');
      print('WeatherService: Stack trace: $stackTrace');
    }
    
    // Fallback to Amsterdam
    print('WeatherService: Falling back to Amsterdam');
    return getWeather('Amsterdam');
  }

  static Future<Map<String, dynamic>?> getWeather(String city) async {
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