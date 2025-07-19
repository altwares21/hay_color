class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;
  final String weatherCondition;
  final double windSpeed;         // daily wind speed
  final int humidity;             // daily humidity %
  final int precipitationChance; // daily precipitation chance %

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
    required this.weatherCondition,
    required this.windSpeed,
    required this.humidity,
    required this.precipitationChance,
  });
}

// Make sure getWeatherDescription is declared here BEFORE WeatherData class
String getWeatherDescription(int code) {
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

class WeatherData {
  final double currentTemperature;
  final String weatherCondition;
  final int weatherCode;
  final double windSpeed;
  final int humidity;             // current humidity %
  final int precipitationChance; // current precipitation chance %
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.currentTemperature,
    required this.weatherCondition,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.precipitationChance,
    required this.dailyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final currentWeather = json['current_weather'];
    if (currentWeather == null || currentWeather is! Map) {
      throw FormatException("Invalid or missing 'current_weather' data");
    }

    final double temp = (currentWeather['temperature'] as num?)?.toDouble() ?? 0.0;
    final int code = (currentWeather['weathercode'] as num?)?.toInt() ?? 0;
    final double wind = (currentWeather['windspeed'] as num?)?.toDouble() ?? 0.0;

    // For current humidity & precipitation chance, you need to get from json, e.g.:
    // Adjust keys to match your API response structure
    final int humidityCurrent = (json['current_humidity'] as num?)?.toInt() ?? 0;
    final int precipitationCurrent = (json['current_precipitation_chance'] as num?)?.toInt() ?? 0;

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

      // Also parse daily windspeed, humidity, precipitationChance if available
      final List<double> windSpeeds = (daily['windspeed_10m_max'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
          List.filled(times.length, 0.0);
      final List<int> humidities = (daily['humidity_2m_max'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          List.filled(times.length, 0);
      final List<int> precipitationChances = (daily['precipitation_probability_max'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          List.filled(times.length, 0);

      for (int i = 0; i < times.length && i < 7; i++) {
        try {
          forecastList.add(DailyForecast(
            date: DateTime.parse(times[i]).toLocal(),
            minTemp: minTemps[i],
            maxTemp: maxTemps[i],
            weatherCode: codes[i],
            weatherCondition: getWeatherDescription(codes[i]),
            windSpeed: windSpeeds.length > i ? windSpeeds[i] : 0.0,
            humidity: humidities.length > i ? humidities[i] : 0,
            precipitationChance: precipitationChances.length > i ? precipitationChances[i] : 0,
          ));
        } catch (_) {}
      }
    }

    return WeatherData(
      currentTemperature: temp,
      weatherCondition: getWeatherDescription(code),
      weatherCode: code,
      windSpeed: wind,
      humidity: humidityCurrent,
      precipitationChance: precipitationCurrent,
      dailyForecast: forecastList,
    );
  }
}
