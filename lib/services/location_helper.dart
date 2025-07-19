import 'package:geocoding/geocoding.dart';

Future<String> getPlaceName(double lat, double lon) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      final city = place.locality?.trim();
      final adminArea = place.subAdministrativeArea?.trim();
      final country = place.country?.trim() ?? '';

      final location = city?.isNotEmpty == true
          ? '$city, $country'
          : adminArea?.isNotEmpty == true
          ? '$adminArea, $country'
          : country;

      return location;
    }
  } catch (e) {
    print('Error getting place name: $e');
  }
  return 'Unknown Location';
}
