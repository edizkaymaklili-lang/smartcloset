import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class LocationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Check if location permission is already granted (without asking)
  Future<bool> isPermissionGranted() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Check if location services are enabled and permissions are granted.
  /// Requests permission if not yet granted.
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
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Reverse geocode using Nominatim (OpenStreetMap) - free, no API key, works on web
  Future<({String? city, String? country})?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': latitude,
          'lon': longitude,
          'zoom': 10,
          'addressdetails': 1,
        },
        options: Options(headers: {
          if (!kIsWeb) 'User-Agent': 'StilAsist/1.0',
          'Accept-Language': 'en',
        }),
      );

      final data = response.data;
      final address = data['address'];

      if (address == null) return null;

      // Try to get city name - prefer larger administrative areas
      // that weather APIs can recognize
      String? city = address['city'] ??
          address['town'] ??
          address['state'] ??
          address['province'] ??
          address['county'] ??
          address['municipality'] ??
          address['village'];

      String? country = address['country'];

      if (city != null) {
        city = _normalizeCityName(city);
      }

      return (city: city, country: country);
    } catch (e) {
      return null;
    }
  }

  /// Get current location and return city name
  Future<String?> getCurrentCity() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final location = await getLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final city = location?.city;
      if (city == null) return null;

      // Verify the city name is recognized by weather API (Open-Meteo geocoding)
      final isValid = await _verifyCityName(city);
      if (isValid) return city;

      // If city name is not recognized, try with country appended
      final country = location?.country;
      if (country != null) {
        final cityWithCountry = '$city, $country';
        final isValidWithCountry = await _verifyCityName(cityWithCountry);
        if (isValidWithCountry) return city;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verify a city name exists in Open-Meteo geocoding API
  Future<bool> _verifyCityName(String cityName) async {
    try {
      final response = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': cityName,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
      );
      final data = response.data;
      return data['results'] != null && (data['results'] as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Normalize city names to match our city list
  String _normalizeCityName(String cityName) {
    final normalized = cityName.trim();

    final cityMap = {
      // Turkish cities
      'İstanbul': 'Istanbul',
      'İzmir': 'Izmir',
      'Eskişehir': 'Eskisehir',
      'Diyarbakır': 'Diyarbakir',
      'Balıkesir': 'Balikesir',

      // Northern Cyprus cities
      'Lefkoşa': 'Nicosia',
      'Lefkosa': 'Nicosia',
      'Girne': 'Kyrenia',
      'Gazi Mağusa': 'Famagusta',
      'Gazimağusa': 'Famagusta',
      'Güzelyurt': 'Morphou',
      'İskele': 'Trikomo',
      'Kyrenia District': 'Kyrenia',
      'Famagusta District': 'Famagusta',
      'Nicosia District': 'Nicosia',
      'Girne District': 'Kyrenia',

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
