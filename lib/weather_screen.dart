import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/weather_service.dart';
import 'models/weather_models.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _error;

  final PageController _pageController = PageController(viewportFraction: 0.7);

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final backgroundColor = getBackgroundColorForWeather(_weatherData!.weatherCode);
    final cardColor = Colors.white.withOpacity(0.8);
    final cardTextColor = Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text('Weekly Forecast'),
        foregroundColor: cardTextColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current weather card
                        Card(
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  getColoredWeatherIcon(_weatherData!.weatherCode),
                                  size: 64,
                                  color: getWeatherIconColor(_weatherData!.weatherCode),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_weatherData!.currentTemperature.toStringAsFixed(1)}°C',
                                  style: TextStyle(fontSize: 32, color: cardTextColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _weatherData!.weatherCondition,
                                  style: TextStyle(fontSize: 18, color: cardTextColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '7-Day Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cardTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _weatherData!.dailyForecast.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final day = _weatherData!.dailyForecast[index];
                              final isToday = day.date.year == DateTime.now().year &&
                                  day.date.month == DateTime.now().month &&
                                  day.date.day == DateTime.now().day;
                              final dayText =
                                  '${isToday ? "Today" : _weekdayName(day.date.weekday)} - ${day.date.month}/${day.date.day}';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          getColoredWeatherIcon(day.weatherCode),
                                          color: getWeatherIconColor(day.weatherCode),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          dayText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: cardTextColor,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Min: ${day.minTemp.toStringAsFixed(1)}°C',
                                          style: TextStyle(color: cardTextColor),
                                        ),
                                        Text(
                                          'Max: ${day.maxTemp.toStringAsFixed(1)}°C',
                                          style: TextStyle(color: cardTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[(weekday - 1) % 7];
  }

  Color getWeatherIconColor(int weatherCode) {
    if (weatherCode == 0) return Colors.yellow.shade700; // sunny
    if (weatherCode >= 1 && weatherCode <= 3) return Colors.grey; // cloudy
    if ((weatherCode >= 45 && weatherCode <= 48) ||
        (weatherCode >= 51 && weatherCode <= 57) ||
        (weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return Colors.blueGrey.shade800; // rain/dark gray
    }
    if ((weatherCode >= 71 && weatherCode <= 86)) return Colors.lightBlue.shade300; // snow
    if (weatherCode >= 95 && weatherCode <= 99) return Colors.deepPurple; // thunderstorm
    return Colors.grey; // default gray
  }

  IconData getColoredWeatherIcon(int weatherCode) {
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
}
