import 'package:flutter/material.dart';

// --- HourlyForecast should be a top-level class ---
class HourlyForecast {
  final DateTime time;
  final double temperature;

  HourlyForecast({required this.time, required this.temperature});
}

IconData getWeatherIcon(int weatherCode) {
  // WMO Weather interpretation codes (WW)
  // Source: Open-Meteo documentation & general WMO code interpretations
  switch (weatherCode) {
  // Clear, Mainly Clear, Partly Cloudy, Overcast
    case 0: // Clear sky
      return Icons.wb_sunny_rounded; // Or Icons.brightness_7_rounded for a more generic sun
    case 1: // Mainly clear
      return Icons.wb_cloudy_outlined; // Or Icons.partly_cloudy_day_rounded if you have it
    case 2: // Partly cloudy
      return Icons.cloud_outlined; // Or Icons.wb_cloudy_rounded
    case 3: // Overcast
      return Icons.cloud_rounded; // Or Icons.wb_cloudy_filled_rounded

  // Fog
    case 45: // Fog
    case 48: // Depositing rime fog
      return Icons.foggy; // Flutter SDK 3.10+ specific, or use Icons.filter_drama_rounded as placeholder

  // Drizzle
    case 51: // Drizzle: Light intensity
    case 53: // Drizzle: Moderate intensity
    case 55: // Drizzle: Dense intensity
      return Icons.grain_rounded; // Placeholder, consider specific drizzle icon
    case 56: // Freezing Drizzle: Light intensity
    case 57: // Freezing Drizzle: Dense intensity
      return Icons.ac_unit_rounded; // Placeholder, shows snowflake, as freezing drizzle is icy

  // Rain
    case 61: // Rain: Slight intensity
      return Icons.water_drop_outlined; // Or Icons.umbrella_rounded
    case 63: // Rain: Moderate intensity
      return Icons.water_drop_rounded;  // Or Icons.beach_access_rounded
    case 65: // Rain: Heavy intensity
      return Icons.waves_rounded; // Or Icons.shower_rounded for a heavier rain look

  // Freezing Rain
    case 66: // Freezing Rain: Light intensity
    case 67: // Freezing Rain: Heavy intensity
      return Icons.severe_cold_rounded; // Placeholder, indicates cold and potentially icy rain

  // Snowfall
    case 71: // Snow fall: Slight intensity
      return Icons.ac_unit_outlined; // Light snow
    case 73: // Snow fall: Moderate intensity
      return Icons.ac_unit_rounded;  // Moderate snow
    case 75: // Snow fall: Heavy intensity
      return Icons.snowing; // Flutter SDK 3.10+ specific, or use Icons.cloudy_snowing as placeholder
    case 77: // Snow grains
      return Icons.grain_rounded; // Similar to drizzle but for snow

  // Showers
    case 80: // Rain showers: Slight
      return Icons.shower_outlined; // Placeholder, or a lighter version of shower
    case 81: // Rain showers: Moderate
    case 82: // Rain showers: Violent
      return Icons.shower_rounded; // Represents rain showers

    case 85: // Snow showers slight
      return Icons.cloudy_snowing; // Placeholder for snow showers
    case 86: // Snow showers heavy
      return Icons.snowing; // Flutter SDK 3.10+ or another heavy snow shower placeholder

  // Thunderstorm
    case 95: // Thunderstorm: Slight or moderate
      return Icons.thunderstorm_outlined;
    case 96: // Thunderstorm with slight hail
    case 99: // Thunderstorm with heavy hail
      return Icons.thunderstorm_rounded; // More intense thunderstorm

    default: // Unknown or not specifically handled
      return Icons.help_outline_rounded; // A generic icon for unmapped codes
  }
}

class WeatherData {
  final double currentTemperature;
  final String weatherCondition;
  final int weatherCode;
  final List<HourlyForecast> hourlyForecast; // Now HourlyForecast is recognized

  WeatherData({
    required this.currentTemperature,
    required this.weatherCondition,
    required this.weatherCode,
    required this.hourlyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // ... (rest of your fromJson method - it should be correct if HourlyForecast is defined)
    // --- Current Weather Parsing ---
    final currentWeather = json['current_weather'];
    if (currentWeather == null || currentWeather is! Map) {
      print("WeatherData.fromJson: Invalid or missing 'current_weather' data.");
      throw FormatException("Invalid or missing 'current_weather' data in JSON response");
    }

    final double temp = (currentWeather['temperature'] as num?)?.toDouble() ?? 0.0;
    final int code = (currentWeather['weathercode'] as num?)?.toInt() ?? 0;

    // --- Hourly Forecast Parsing ---
    List<HourlyForecast> forecastList = [];
    final hourly = json['hourly'];

    if (hourly == null || hourly is! Map) {
      print("WeatherData.fromJson: 'hourly' data is missing or not a Map.");
    } else {
      final timesDynamic = hourly['time'];
      final temperaturesDynamic = hourly['temperature_2m'];

      if (timesDynamic == null || timesDynamic is! List) {
        print("WeatherData.fromJson: 'hourly.time' is missing or not a List.");
      } else if (temperaturesDynamic == null || temperaturesDynamic is! List) {
        print("WeatherData.fromJson: 'hourly.temperature_2m' is missing or not a List.");
      } else if (timesDynamic.isEmpty) {
        print("WeatherData.fromJson: 'hourly.time' list is empty.");
      } else if (timesDynamic.length != temperaturesDynamic.length) {
        print("WeatherData.fromJson: 'hourly.time' and 'hourly.temperature_2m' lists have different lengths.");
      } else {
        print("WeatherData.fromJson: Processing ${timesDynamic.length} hourly entries.");

        final List<String> times = timesDynamic.map((e) => e.toString()).toList();
        final List<double> temperatures = temperaturesDynamic.map((e) {
          if (e is num) return e.toDouble();
          if (e is String) return double.tryParse(e) ?? 0.0;
          return 0.0;
        }).toList();

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final tomorrowStart = DateTime(now.year, now.month, now.day + 1);

        for (int i = 0; i < times.length; i++) {
          try {
            DateTime forecastTimeUtc = DateTime.parse(times[i]);
            DateTime forecastTimeLocal = forecastTimeUtc.toLocal();

            if (!forecastTimeLocal.isBefore(todayStart) && forecastTimeLocal.isBefore(tomorrowStart)) {
              forecastList.add(HourlyForecast( // This will now work
                time: forecastTimeLocal,
                temperature: temperatures[i],
              ));
            }
          } catch (e) {
            print("Error parsing time or processing hourly entry: '${times[i]}' - $e");
          }
        }
        if (forecastList.isEmpty && timesDynamic.isNotEmpty) {
          print("WeatherData.fromJson: Hourly data was present, but filter resulted in an empty list for today.");
        }
      }
    }
    if (forecastList.isEmpty) {
      print("WeatherData.fromJson: Final hourlyForecast list is empty.");
    }
    return WeatherData(
      currentTemperature: temp,
      weatherCondition: _getWeatherDescription(code), // Static method, okay inside or outside
      weatherCode: code,
      hourlyForecast: forecastList,
    );
  }

  // _getWeatherDescription can remain a static method of WeatherData or be top-level
  static String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code >= 1 && code <= 3) return 'Mainly clear, partly cloudy, and overcast';
    if (code >= 45 && code <= 48) return 'Fog and depositing rime fog';
    if (code >= 51 && code <= 55) return 'Drizzle: Light, moderate, and dense intensity';
    if (code >= 56 && code <= 57) return 'Freezing Drizzle: Light and dense intensity';
    // TYPO FIX: was 'code', should be 'weatherCode' (or 'code' consistently)
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

// Function to get background color based on weather code
Color getBackgroundColorForWeather(int weatherCode) { // Now Color and Colors are recognized
  // Clear Sky
  if (weatherCode == 0) return Colors.blue.shade300;
  // Mainly Clear, Partly Cloudy, Overcast
  if (weatherCode >= 1 && weatherCode <= 3) return Colors.lightBlue.shade200;
  // Fog
  if (weatherCode >= 45 && weatherCode <= 48) return Colors.grey.shade400;
  // Drizzle
  if (weatherCode >= 51 && weatherCode <= 55) return Colors.blueGrey.shade300;
  // Freezing Drizzle
  if (weatherCode >= 56 && weatherCode <= 57) return Colors.blueGrey.shade400;
  // Rain
  // TYPO FIX: ensure consistent variable name if this was the issue
  if (weatherCode >= 61 && weatherCode <= 65) return Colors.indigo.shade300;
  // Freezing Rain
  if (weatherCode >= 66 && weatherCode <= 67) return Colors.indigo.shade400;
  // Snow Fall
  if (weatherCode >= 71 && weatherCode <= 75) return Colors.lightBlue.shade100;
  // Snow Grains
  if (weatherCode == 77) return Colors.white70;
  // Rain Showers
  if (weatherCode >= 80 && weatherCode <= 82) return Colors.blue.shade400;
  // Snow Showers
  if (weatherCode >= 85 && weatherCode <= 86) return Colors.lightBlue.shade200;
  // Thunderstorm
  if (weatherCode == 95 || (weatherCode >= 96 && weatherCode <= 99)) {
    return Colors.deepPurple.shade700;
  }
  // Default or Unknown
  return Colors.grey.shade300;
}

// Function to determine if text/icons should be light or dark based on background
bool isDarkMode(Color backgroundColor) {
  return backgroundColor.computeLuminance() < 0.4;
}