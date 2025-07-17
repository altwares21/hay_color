import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'services/weather_service.dart';
import 'models/weather_models.dart';

// --- PredefinedLocation class definition ---
class PredefinedLocation {
  final String name;
  final double latitude;
  final double longitude;

  const PredefinedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// --- Top-level final variable for predefined locations ---
final List<PredefinedLocation> _predefinedLocations = [
  const PredefinedLocation(
    name: "New York",
    latitude: 40.7128,
    longitude: -74.0060,
  ),
  const PredefinedLocation(
    name: "London",
    latitude: 51.5074,
    longitude: -0.1278,
  ),
  const PredefinedLocation(
      name: "Paris",
      latitude: 48.8566,
      longitude: 2.3522),
  const PredefinedLocation(
    name: "Tokyo",
    latitude: 35.6895,
    longitude: 139.6917,
  ),
  const PredefinedLocation(
    name: "Sydney",
    latitude: -33.8688,
    longitude: 151.2093,
  ),
  const PredefinedLocation(
    name: "Corozal",
    latitude: 18.3480,
    longitude: -66.3157,
  ),
  const PredefinedLocation(
    name: "New Delhi",
    latitude: 28.6139,
    longitude: 77.2090,
  ),
];

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();

  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  String _displayedLocationName =
      ""; // Initialize as empty for cleaner initial display
  PredefinedLocation? _selectedPredefinedLocation;

  Color _currentBackgroundColor =
      Colors.blueGrey.shade200; // A more neutral default
  ThemeData _currentTextTheme = ThemeData.light();

  @override
  void initState() {
    super.initState();
    // Set a default theme before fetching data
    _updateThemeColors(-1); // Use -1 or a specific code for a "default" look
    _fetchWeatherDataForDeviceLocation();
  }

  void _updateThemeColors(int weatherCode) {
    _currentBackgroundColor = getBackgroundColorForWeather(weatherCode);
    bool useDarkText = !isDarkMode(_currentBackgroundColor);

    _currentTextTheme = ThemeData(
      brightness: useDarkText ? Brightness.light : Brightness.dark,
      primarySwatch: Colors.blue, // Base for some default widget colors
      scaffoldBackgroundColor:
          _currentBackgroundColor, // Will be overridden by AnimatedContainer
      appBarTheme: AppBarTheme(
        backgroundColor: _currentBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: useDarkText ? Colors.black87 : Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: useDarkText ? Colors.black87 : Colors.white,
        ),
      ),
      textTheme: TextTheme(
        // For main temperature display
        displayMedium: TextStyle(
          color: useDarkText ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // For weather condition
        headlineSmall: TextStyle(
          color: useDarkText ? Colors.black87 : Colors.white,
        ),
        // For section titles like "Hourly Forecast"
        titleLarge: TextStyle(
          color: useDarkText
              ? Colors.black
              : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        // For general text in cards, lists
        bodyMedium: TextStyle(
          color: useDarkText ? Colors.black87 : Colors.white,
        ),
        // For smaller text in cards, like time in hourly forecast
        titleMedium: TextStyle(
          color: useDarkText ? Colors.black87 : Colors.white,
        ),
        titleSmall: TextStyle(
          color: useDarkText ? Colors.black54 : Colors.white70,
        ),
      ),
      iconTheme: IconThemeData(
        color: useDarkText ? Colors.black54 : Colors.white70,
      ),
      // --- CORRECTED SECTION ---
      cardTheme: CardThemeData(
        // Changed from CardTheme to CardThemeData
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: _currentBackgroundColor.withAlpha(
          230,
        ), // Slightly less opaque than appbar
      ),
    );
  }

  Future<void> _fetchWeatherDataForDeviceLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedPredefinedLocation = null;
      _displayedLocationName = "Current Location"; // Update display name
    });
    try {
      _currentPosition = await _getCurrentLocation();
      if (_currentPosition != null) {
        await _fetchWeather(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      } else {
        setState(() {
          _errorMessage = "Could not determine current location.";
          _isLoading = false;
          _updateThemeColors(-1); // Reset theme on error
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
        _updateThemeColors(-1); // Reset theme on error
      });
    }
  }

  Future<void> _fetchWeatherForLocation(
    String name,
    double latitude,
    double longitude,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _displayedLocationName = name; // Update display name
    });
    await _fetchWeather(latitude, longitude);
  }

  Future<void> _fetchWeather(double latitude, double longitude) async {
    try {
      final data = await _weatherService.fetchWeather(latitude, longitude);
      setState(() {
        _weatherData = data;
        _isLoading = false;
        _errorMessage = '';
        _updateThemeColors(data.weatherCode);
      });
    } catch (e) {
      setState(() {
        _weatherData = null;
        // Keep _displayedLocationName as is, so user knows what location failed
        _errorMessage =
            "Failed to fetch weather for $_displayedLocationName.\n${e.toString().replaceFirst("Exception: ", "")}";
        _isLoading = false;
        _updateThemeColors(-1); // Reset theme on error
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    // ... (your existing _getCurrentLocation method)
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    // Apply the dynamic theme using the Theme widget at the root of the screen's UI.
    return Theme(
      data: _currentTextTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color:
            _currentBackgroundColor, // This animates the overall background color
        child: Scaffold(
          backgroundColor: Colors
              .transparent, // Scaffold is transparent to show AnimatedContainer's color
          appBar: AppBar(
            // AppBar's appearance is controlled by appBarTheme in _currentTextTheme
            title: Text(
              _displayedLocationName.isNotEmpty
                  ? _displayedLocationName
                  : 'Weather',
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _fetchWeatherDataForDeviceLocation,
                tooltip: 'Current Location',
              ),
            ],
          ),
          drawer: _buildDrawer(),
          body: SafeArea(
            // Ensures content is not obscured by notches, status bars
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    ) // Make indicator visible
                  : _errorMessage.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: isDarkMode(_currentBackgroundColor)
                              ? Colors.red.shade200
                              : Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _weatherData == null
                  ? Text(
                      'Select a location or use current location.',
                      style: _currentTextTheme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    )
                  : _buildWeatherUI(), // This method now builds the main card
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    Color drawerActualBg =
        Theme.of(context).drawerTheme.backgroundColor ??
        _currentBackgroundColor;
    bool useDarkTextOnDrawer = !isDarkMode(drawerActualBg);
    Color? iconColor = useDarkTextOnDrawer ? Colors.black54 : Colors.white70;
    TextStyle? textStyle = TextStyle(
      color: useDarkTextOnDrawer ? Colors.black87 : Colors.white,
    );
    TextStyle? headerTextStyle = TextStyle(
      color: useDarkTextOnDrawer ? Colors.grey.shade700 : Colors.grey.shade400,
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              // Use a slightly darker/lighter shade of the background for the header
              color: _currentBackgroundColor,
            ),
            child: Center(
              child: Text(
                'Select Location',
                style: _currentTextTheme.textTheme.titleLarge?.copyWith(
                  // Ensure drawer header text contrasts with its specific background
                  color: isDarkMode(_currentBackgroundColor)
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.my_location_outlined, color: iconColor),
            title: Text('Current Device Location', style: textStyle),
            selected:
                _selectedPredefinedLocation == null &&
                _displayedLocationName == "Current Location",
            onTap: () {
              Navigator.of(context).pop();
              _fetchWeatherDataForDeviceLocation();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text("Favorites", style: headerTextStyle),
          ),
          for (var location in _predefinedLocations)
            ListTile(
              leading: Icon(Icons.location_city, color: iconColor),
              title: Text(location.name, style: textStyle),
              selected: _selectedPredefinedLocation?.name == location.name,
              onTap: () {
                Navigator.of(context).pop();
                // No need to call setState for _selectedPredefinedLocation here if
                // _fetchWeatherForLocation updates _displayedLocationName and triggers a rebuild
                _fetchWeatherForLocation(
                  location.name,
                  location.latitude,
                  location.longitude,
                );
                // Update _selectedPredefinedLocation after initiating fetch,
                // so the selection highlight updates immediately
                setState(() {
                  _selectedPredefinedLocation = location;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherUI() {
    if (_weatherData == null) return const SizedBox.shrink();

    final textTheme = _currentTextTheme.textTheme;
    final iconThemeColor = _currentTextTheme.iconTheme.color;

    // Define a fixed width for the main weather card
    // You can adjust this value, or calculate it based on screen width
    // e.g., double cardWidth = MediaQuery.of(context).size.width * 0.8;
    const double cardWidth = 320.0; // Example fixed width

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment
            .center, // Center the card horizontally in the column
        children: [
          SizedBox(
            // Constrain the width of the Card
            width: cardWidth,
            child: Card(
              color: isDarkMode(_currentBackgroundColor)
                  ? Colors.grey[850] // Slightly adjusted opacity
                  : Colors.white, // Slightly adjusted opacity
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 20.0,
                ), // Adjusted padding slightly
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Still takes minimum vertical space
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      getWeatherIcon(_weatherData!.weatherCode),
                      size:
                          80, // Slightly smaller icon to give more space for text
                      color: iconThemeColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_weatherData!.currentTemperature.round()}°C',
                      style: textTheme.displayMedium?.copyWith(
                        fontSize: 56,
                      ), // Adjust font size if needed
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _weatherData!.weatherCondition,
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                      ), // Adjust font size if needed
                      textAlign: TextAlign
                          .center, // Text will wrap if too long due to SizedBox constraint
                      maxLines:
                          2, // Optional: Limit to 2 lines and show ellipsis
                      overflow:
                          TextOverflow.ellipsis, // Optional: if maxLines is set
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Today\'s Hourly Forecast', style: textTheme.titleLarge),
          const SizedBox(height: 10),
          _buildHourlyForecastList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastList() {
    if (_weatherData == null || _weatherData!.hourlyForecast.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No hourly forecast available for today.',
          style: _currentTextTheme.textTheme.bodyMedium,
        ),
      );
    }

    final textTheme = _currentTextTheme.textTheme;

    return SizedBox(
      height: 130, // Increased height for better look
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weatherData!.hourlyForecast.length,
        itemBuilder: (context, index) {
          final hourly = _weatherData!.hourlyForecast[index];
          // Determine card color for contrast with main background
          Color cardBackgroundColor = isDarkMode(_currentBackgroundColor)
              ? Colors.white // Slightly more opaque
              : Colors.black; // Slightly more opaque
          bool useDarkTextOnCard = !isDarkMode(cardBackgroundColor);

          Color? _ = useDarkTextOnCard ? Colors.black54 : Colors.white70;
          TextStyle? cardTimeStyle = textTheme.titleSmall?.copyWith(
            color: useDarkTextOnCard ? Colors.black54 : Colors.white70,
          );
          TextStyle? cardTempStyle = textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: useDarkTextOnCard ? Colors.black87 : Colors.white,
          );

          return Card(
            color: cardBackgroundColor,
            // Uses CardTheme from _currentTextTheme for shape and elevation
            margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.j().format(hourly.time), // e.g., "5 PM"
                    style: cardTimeStyle,
                  ),
                  const SizedBox(height: 8),
                  Text('${hourly.temperature.round()}°C', style: cardTempStyle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}