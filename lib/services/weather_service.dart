import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static Future<Map<String, dynamic>?> getWeatherForLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return getWeather('Amsterdam');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        return getWeather('Amsterdam');
      }

      // Get current position with timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(Duration(seconds: 10));
      } catch (e) {
        print('Location timeout or error: $e');
        // Try last known position
        position = await Geolocator.getLastKnownPosition();
      }
      
      if (position == null) {
        print('Could not get position');
        return getWeather('Amsterdam');
      }
      
      print('Got position: ${position.latitude}, ${position.longitude}');
      
      // Use coordinates for weather
      final lat = position.latitude;
      final lon = position.longitude;
      
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
          print('Error parsing location name: $e');
        }
        
        print('Weather location: $location');
        
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
        print('Weather API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Location weather error: $e');
      print('Stack trace: $stackTrace');
    }
    
    // Fallback to Amsterdam
    return getWeather('Amsterdam');
  }

  static Future<Map<String, dynamic>?> getWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
        headers: {'User-Agent': 'PlusNews/1.0'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      print('Weather error: $e');
    }
    return null;
  }
}