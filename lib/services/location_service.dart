import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      debugPrint('LocationService: Error getting position: $e');
      return null;
    }
  }

  static Future<String?> getCityFromPosition(Position position) async {
    try {
      // Gebruik wttr.in om locatie naam te krijgen van coordinaten
      final response = await http.get(
        Uri.parse('https://wttr.in/${position.latitude},${position.longitude}?format=j1'),
        headers: {'User-Agent': 'PlusNews/1.0'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final areaName = data['nearest_area']?[0]?['areaName']?[0]?['value'];
        final region = data['nearest_area']?[0]?['region']?[0]?['value'];
        
        if (areaName != null) {
          return areaName;
        }
        return region;
      }
    } catch (e) {
      debugPrint('LocationService: Error getting city name: $e');
    }
    return null;
  }
}
