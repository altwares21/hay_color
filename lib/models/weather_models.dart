import 'package:flutter/material.dart';

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
  });
}

IconData getWeatherIcon(int weatherCode) {
  switch (weatherCode) {
    case 0:
      return Icons.wb_sunny_rounded;
    case 1:
      return Icons.wb_cloudy_outlined;
    case 2:
      return Icons.cloud_outlined;
    case 3:
      return Icons.cloud_rounded;
    case 45:
    case 48:
      return Icons.foggy;
    case 51:
    case 53:
    case 55:
      return Icons.grain_rounded;
    case 56:
    case 57:
      return Icons.ac_unit_rounded;
    case 61:
      return Icons.water_drop_outlined;
    case 63:
      return Icons.water_drop_rounded;
    case 65:
      return Icons.waves_rounded;
    case 66:
    case 67:
      return Icons.severe_cold_rounded;
    case 71:
      return Icons.ac_unit_outlined;
    case 73:
      return Icons.ac_unit_rounded;
    case 75:
      return Icons.snowing;
    case 77:
      return Icons.grain_rounded;
    case 80:
      return Icons.shower_outlined;
    case 81:
    case 82:
      return Icons.shower_rounded;
    case 85:
      return Icons.cloudy_snowing;
    case 86:
      return Icons.snowing;
    case 95:
      return Icons.thunderstorm_outlined;
    case 96:
    case 99:
      return Icons.thunderstorm_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

class WeatherData {
  final double currentTemperature;
  final String weatherCondition;
  final int weatherCode;
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.currentTemperature,
    required this.weatherCondition,
    required this.weatherCode,
    required this.dailyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final currentWeather = json['current_weather'];
    if (currentWeather == null || currentWeather is! Map) {
      throw FormatException("Invalid or missing 'current_weather' data");
    }

    final double temp = (currentWeather['temperature'] as num?)?.toDouble() ?? 0.0;
    final int code = (currentWeather['weathercode'] as num?)?.toInt() ?? 0;

    List<DailyForecast> forecastList = [];
    final daily = json['daily'];

    if (daily != null &&
        daily['time'] != null &&
        daily['temperature_2m_max'] != null &&
        daily['temperature_2m_min'] != null &&
        daily['weathercode'] != null) {
      final List<String> times = (daily['time'] as List).map((e) => e.toString()).toList();
      final List<double> maxTemps = (daily['temperature_2m_max'] as List).map((e) => (e as num).toDouble()).toList();
      final List<double> minTemps = (daily['temperature_2m_min'] as List).map((e) => (e as num).toDouble()).toList();
      final List<int> codes = (daily['weathercode'] as List).map((e) => (e as num).toInt()).toList();

      for (int i = 0; i < times.length && i < 7; i++) {
        try {
          forecastList.add(DailyForecast(
            date: DateTime.parse(times[i]).toLocal(),
            minTemp: minTemps[i],
            maxTemp: maxTemps[i],
            weatherCode: codes[i],
          ));
        } catch (_) {}
      }
    }

    return WeatherData(
      currentTemperature: temp,
      weatherCondition: _getWeatherDescription(code),
      weatherCode: code,
      dailyForecast: forecastList,
    );
  }

  static String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code >= 1 && code <= 3) return 'Mainly clear, partly cloudy, and overcast';
    if (code >= 45 && code <= 48) return 'Fog and depositing rime fog';
    if (code >= 51 && code <= 55) return 'Drizzle: Light, moderate, and dense intensity';
    if (code >= 56 && code <= 57) return 'Freezing Drizzle: Light and dense intensity';
    if (code >= 61 && code <= 65) return 'Rain: Slight, moderate and heavy intensity';
    if (code >= 66 && code <= 67) return 'Freezing Rain: Light and heavy intensity';
    if (code >= 71 && code <= 75) return 'Snow fall: Slight, moderate, and heavy intensity';
    if (code == 77) return 'Snow grains';
    if (code >= 80 && code <= 82) return 'Rain showers: Slight, moderate, and violent';
    if (code >= 85 && code <= 86) return 'Snow showers slight and heavy';
    if (code == 95) return 'Thunderstorm: Slight or moderate';
    if (code >= 96 && code <= 99) return 'Thunderstorm with slight and heavy hail';
    return 'Unknown ($code)';
  }
}

Color getBackgroundColorForWeather(int weatherCode) {
  if (weatherCode == 0) return Colors.blue.shade300;
  if (weatherCode >= 1 && weatherCode <= 3) return Colors.lightBlue.shade200;
  if (weatherCode >= 45 && weatherCode <= 48) return Colors.grey.shade400;
  if (weatherCode >= 51 && weatherCode <= 55) return Colors.blueGrey.shade300;
  if (weatherCode >= 56 && weatherCode <= 57) return Colors.blueGrey.shade400;
  if (weatherCode >= 61 && weatherCode <= 65) return Colors.indigo.shade300;
  if (weatherCode >= 66 && weatherCode <= 67) return Colors.indigo.shade400;
  if (weatherCode >= 71 && weatherCode <= 75) return Colors.lightBlue.shade100;
  if (weatherCode == 77) return Colors.white70;
  if (weatherCode >= 80 && weatherCode <= 82) return Colors.blue.shade400;
  if (weatherCode >= 85 && weatherCode <= 86) return Colors.lightBlue.shade200;
  if (weatherCode == 95 || (weatherCode >= 96 && weatherCode <= 99)) {
    return Colors.deepPurple.shade700;
  }
  return Colors.grey.shade300;
}

bool isDarkMode(Color backgroundColor) {
  return backgroundColor.computeLuminance() < 0.4;
}
