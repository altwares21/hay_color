import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double latitude, double longitude) async {
    final String apiUrl =
        '$_baseUrl?latitude=$latitude&longitude=$longitude&current_weather=true'
        '&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception(
            'Failed to load weather data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in WeatherService.fetchWeather: $e');
      throw Exception('Error fetching weather: $e');
    }
  }
}
