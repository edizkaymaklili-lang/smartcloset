import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check if location services are enabled and permissions are granted
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current coordinates (latitude and longitude)
  Future<({double latitude, double longitude})?> getCurrentCoordinates() async {
    try {
      // Check permissions first
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      // Location fetch failed
      return null;
    }
  }

  /// Get location details (city and country) from coordinates
  Future<({String? city, String? country})?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Get city name
        String? city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;

        // Normalize city name
        if (city != null) {
          city = _normalizeCityName(city);
        }

        // Get country name
        String? country = placemark.country;

        return (city: city, country: country);
      }

      return null;
    } catch (e) {
      // Geocoding failed
      return null;
    }
  }

  /// Get current location and return city name
  Future<String?> getCurrentCity() async {
    try {
      // Check permissions first
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Use the new method to get location details
      final location = await getLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return location?.city;
    } catch (e) {
      // Location fetch failed
      return null;
    }
  }

  /// Normalize city names to match our city list
  String _normalizeCityName(String cityName) {
    final normalized = cityName.trim();

    // Map common variations and special characters to standard English names
    final cityMap = {
      // Turkish cities
      'İstanbul': 'Istanbul',
      'İzmir': 'Izmir',
      'Eskişehir': 'Eskisehir',
      'Diyarbakır': 'Diyarbakir',
      'Balıkesir': 'Balikesir',

      // Other common variations
      'New York City': 'New York',
      'NYC': 'New York',
      'LA': 'Los Angeles',
      'San Fran': 'San Francisco',
      'SF': 'San Francisco',
      'Sao Paulo': 'São Paulo',
      'Rio': 'Rio de Janeiro',
      'Buenos Aries': 'Buenos Aires',
      'Tel Aviv-Yafo': 'Tel Aviv',
      'Ho Chi Minh': 'Ho Chi Minh City',
      'Saigon': 'Ho Chi Minh City',
      'Peking': 'Beijing',
      'Bombay': 'Mumbai',
      'Calcutta': 'Kolkata',
      'Madras': 'Chennai',
    };

    return cityMap[normalized] ?? normalized;
  }

  /// Open app settings for location permission
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
