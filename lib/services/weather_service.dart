// lib/services/weather_service.dart (or lib/weather_service.dart)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double latitude, double longitude) async {
    final String apiUrl =
        '$_baseUrl?latitude=$latitude&longitude=$longitude&current_weather=true&hourly=temperature_2m,weathercode&forecast_days=1';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        // More specific error handling based on status code
        throw Exception('Failed to load weather data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // Handle network errors or other exceptions during the API call
      print('Error in WeatherService.fetchWeather: $e');
      throw Exception('Error fetching weather: $e');
    }
  }
}