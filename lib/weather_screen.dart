import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/weather_service.dart';
import '../models/weather_models.dart';

/// Get a readable place name (City, Country) with fallbacks
Future<String> getPlaceName(double lat, double lon) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final city = place.locality ?? place.subAdministrativeArea ?? place.name ?? '';
      final country = place.country ?? '';
      if (city.isNotEmpty && country.isNotEmpty) {
        return '$city, $country';
      } else if (country.isNotEmpty) {
        return country;
      } else if (city.isNotEmpty) {
        return city;
      }
    }
  } catch (e) {
    print('Error getting place name: $e');
  }
  return 'Unknown Location';
}

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
  String? _locationName;

  final PageController _pageController = PageController(viewportFraction: 0.7);
  int? _selectedForecastIndex;

  final TextEditingController _citySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather({String? cityName, bool useCurrentLocation = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedForecastIndex = null;
      _locationName = null;
    });

    try {
      double lat;
      double lon;
      String locationDisplay;

      if (useCurrentLocation) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        lat = position.latitude;
        lon = position.longitude;
        locationDisplay = await getPlaceName(lat, lon);
      } else if (cityName != null && cityName.isNotEmpty) {
        List<Location> locations = await locationFromAddress(cityName);
        if (locations.isEmpty) {
          throw Exception('Could not find location for "$cityName"');
        }
        lat = locations.first.latitude;
        lon = locations.first.longitude;
        locationDisplay = await getPlaceName(lat, lon);
      } else {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        lat = position.latitude;
        lon = position.longitude;
        locationDisplay = await getPlaceName(lat, lon);
      }

      final weather = await _weatherService.fetchWeather(lat, lon);

      setState(() {
        _weatherData = weather;
        _locationName = locationDisplay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayStr = weekdays[(date.weekday - 1) % 7];
    return '$weekdayStr, ${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[(weekday - 1) % 7];
  }

  String _getWeatherImage(int code) {
    if (code == 0) return 'assets/sunny.jpg';
    if (code >= 1 && code <= 3) return 'assets/cloudy.jpg';
    if ((code >= 45 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'assets/rainy.webp';
    }
    if ((code >= 71 && code <= 86)) return 'assets/snowy.jpg';
    if (code >= 95 && code <= 99) return 'assets/stormy.jpeg';
    return 'assets/cloudy.jpg';
  }

  Color getAppBarColor(int weatherCode) {
    if (weatherCode == 0) return Colors.orange.shade700;
    if (weatherCode >= 1 && weatherCode <= 3) return Colors.blueGrey.shade700;
    if ((weatherCode >= 45 && weatherCode <= 48) ||
        (weatherCode >= 51 && weatherCode <= 57) ||
        (weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return Colors.blue.shade700;
    }
    if ((weatherCode >= 71 && weatherCode <= 86)) {
      return Colors.lightBlue.shade400;
    }
    if (weatherCode >= 95 && weatherCode <= 99) {
      return Colors.deepPurple.shade700;
    }
    return Colors.blueGrey.shade700;
  }

  Color getWeatherIconColor(int weatherCode) {
    if (weatherCode == 0) return Colors.yellow.shade700;
    if (weatherCode >= 1 && weatherCode <= 3) return Colors.grey;
    if ((weatherCode >= 45 && weatherCode <= 48) ||
        (weatherCode >= 51 && weatherCode <= 57) ||
        (weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return Colors.blue;
    }
    if ((weatherCode >= 71 && weatherCode <= 86)) {
      return Colors.lightBlue.shade300;
    }
    if (weatherCode >= 95 && weatherCode <= 99) return Colors.deepPurple;
    return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    final cardColor = Colors.white.withOpacity(0.8);
    final cardTextColor = Colors.black87;

    final bool showingCurrent = _selectedForecastIndex == null;
    final int weatherCode = showingCurrent
        ? _weatherData!.weatherCode
        : _weatherData!.dailyForecast[_selectedForecastIndex!].weatherCode;

    final DateTime displayDate = showingCurrent
        ? DateTime.now()
        : _weatherData!.dailyForecast[_selectedForecastIndex!].date;

    final String displayCondition = showingCurrent
        ? _weatherData!.weatherCondition
        : getWeatherDescription(
      _weatherData!.dailyForecast[_selectedForecastIndex!].weatherCode,
    );

    final double? currentTemp =
    showingCurrent ? _weatherData!.currentTemperature : null;

    final double? minTemp = showingCurrent
        ? null
        : _weatherData!.dailyForecast[_selectedForecastIndex!].minTemp;
    final double? maxTemp = showingCurrent
        ? null
        : _weatherData!.dailyForecast[_selectedForecastIndex!].maxTemp;

    final double? currentWindSpeed =
    showingCurrent ? _weatherData!.windSpeed : null;
    final int? currentHumidity = showingCurrent ? _weatherData!.humidity : null;
    final int? currentPrecipitationChance = showingCurrent
        ? _weatherData!.precipitationChance
        : null;

    final double? forecastWindSpeed = !showingCurrent
        ? (_weatherData!.dailyForecast[_selectedForecastIndex!].windSpeed ?? null)
        : null;
    final int? forecastHumidity = !showingCurrent
        ? (_weatherData!.dailyForecast[_selectedForecastIndex!].humidity ?? null)
        : null;
    final int? forecastPrecipitationChance = !showingCurrent
        ? (_weatherData!.dailyForecast[_selectedForecastIndex!].precipitationChance ??
        null)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: getAppBarColor(weatherCode).withOpacity(0.8),
        title: const Text('Hay Calor!'),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _getWeatherImage(weatherCode),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          RefreshIndicator(
            onRefresh: () => _loadWeather(),
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
                            // === City search TextField with two buttons ===
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _citySearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search for a city',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.8),
                                      ),
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: (value) {
                                        final city = value.trim();
                                        if (city.isNotEmpty) {
                                          _loadWeather(cityName: city);
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      _citySearchController.clear();
                                      _loadWeather(useCurrentLocation: true);
                                      FocusScope.of(context).unfocus();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(12), // Adjust padding to your liking
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(Icons.my_location),
                                  ),
                                ],
                              ),
                            ),

                            // Location display with icon
                            if (_locationName != null && showingCurrent)
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _locationName!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Main weather card (same as before) ...
                            Card(
                              color: cardColor,
                              margin: const EdgeInsets.symmetric(horizontal: 48),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      _formatDate(displayDate),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: cardTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      getColoredWeatherIcon(weatherCode),
                                      size: 64,
                                      color: getWeatherIconColor(weatherCode),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      displayCondition,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: cardTextColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    if (showingCurrent)
                                      Text(
                                        '${currentTemp!.toStringAsFixed(1)}°C',
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: cardTextColor,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'Low: ${minTemp!.toStringAsFixed(1)}°C',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: cardTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'High: ${maxTemp!.toStringAsFixed(1)}°C',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: cardTextColor,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    if (showingCurrent && currentWindSpeed != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.air,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${currentWindSpeed.toStringAsFixed(1)} m/s wind',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!showingCurrent && forecastWindSpeed != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.air,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${forecastWindSpeed.toStringAsFixed(1)} m/s wind',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    if (showingCurrent && currentHumidity != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.opacity,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$currentHumidity% humidity',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!showingCurrent && forecastHumidity != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.opacity,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$forecastHumidity% humidity',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (showingCurrent && currentPrecipitationChance != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.umbrella,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$currentPrecipitationChance% chance of precipitation',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!showingCurrent &&
                                        forecastPrecipitationChance != null)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.umbrella,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$forecastPrecipitationChance% chance of precipitation',
                                            style: TextStyle(
                                              color: cardTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 7-day forecast horizontal list
                            SizedBox(
                              height: 110,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _weatherData!.dailyForecast.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    if (_selectedForecastIndex == index) {
                                      _selectedForecastIndex = null;
                                    } else {
                                      _selectedForecastIndex = index;
                                    }
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final forecast = _weatherData!.dailyForecast[index];
                                  final bool selected = _selectedForecastIndex == index;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Card(
                                      color: selected
                                          ? cardColor.withOpacity(0.9)
                                          : cardColor.withOpacity(0.6),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _weekdayName(forecast.date.weekday),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: cardTextColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Icon(
                                              getColoredWeatherIcon(forecast.weatherCode),
                                              color: getWeatherIconColor(forecast.weatherCode),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'L: ${forecast.minTemp.toStringAsFixed(0)}°',
                                              style: TextStyle(
                                                color: cardTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'H: ${forecast.maxTemp.toStringAsFixed(0)}°',
                                              style: TextStyle(
                                                color: cardTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
