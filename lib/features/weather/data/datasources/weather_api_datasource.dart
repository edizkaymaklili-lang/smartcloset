import 'package:dio/dio.dart';
import '../../../../core/enums/weather_condition.dart';
import '../../domain/entities/weather_data.dart';

/// Real weather data from Open-Meteo API (free, no API key, CORS-friendly)
class WeatherApiDatasource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<WeatherData> getCurrentWeather({required String city}) async {
    // Step 1: Geocode city name to coordinates
    final geoResponse = await _dio.get(
      'https://geocoding-api.open-meteo.com/v1/search',
      queryParameters: {
        'name': city,
        'count': 1,
        'language': 'en',
        'format': 'json',
      },
    );

    final geoData = geoResponse.data;
    if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
      throw Exception('City not found: $city');
    }

    final location = geoData['results'][0];
    final double lat = (location['latitude'] as num).toDouble();
    final double lon = (location['longitude'] as num).toDouble();
    final String resolvedCity = location['name'] as String? ?? city;

    // Step 2: Get weather data from Open-Meteo
    final weatherResponse = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
        'hourly': 'temperature_2m,weather_code,precipitation_probability',
        'forecast_days': 1,
        'timezone': 'auto',
      },
    );

    final data = weatherResponse.data;
    final current = data['current'];

    final tempC = (current['temperature_2m'] as num).toDouble();
    final feelsLikeC = (current['apparent_temperature'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toInt();
    final windSpeed = (current['wind_speed_10m'] as num).toDouble() / 3.6; // km/h to m/s
    final precipMm = (current['precipitation'] as num).toDouble();
    final weatherCode = (current['weather_code'] as num).toInt();

    final condition = _mapWmoCode(weatherCode);
    final description = _wmoDescription(weatherCode);

    // Parse hourly forecast
    final hourlyList = <HourlyForecast>[];
    final hourlyData = data['hourly'];
    if (hourlyData != null) {
      final times = hourlyData['time'] as List;
      final temps = hourlyData['temperature_2m'] as List;
      final codes = hourlyData['weather_code'] as List;
      final precips = hourlyData['precipitation_probability'] as List;

      for (int i = 0; i < times.length; i++) {
        final forecastTime = DateTime.parse(times[i] as String);
        hourlyList.add(HourlyForecast(
          time: forecastTime,
          temperature: (temps[i] as num).toDouble(),
          condition: _mapWmoCode((codes[i] as num).toInt()),
          precipitationProbability: (precips[i] as num).toDouble() / 100.0,
        ));
      }
    }

    return WeatherData(
      temperature: tempC,
      feelsLike: feelsLikeC,
      humidity: humidity,
      windSpeed: windSpeed,
      precipitation: precipMm,
      description: description,
      condition: condition,
      cityName: resolvedCity,
      timestamp: DateTime.now(),
      hourlyForecast: hourlyList,
    );
  }

  /// Map WMO weather codes to WeatherCondition
  /// https://open-meteo.com/en/docs#weathervariables
  WeatherCondition _mapWmoCode(int code) {
    if (code == 0 || code == 1) return WeatherCondition.sunny;
    if (code == 2 || code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.cloudy; // fog
    if (code >= 51 && code <= 67) return WeatherCondition.rainy; // drizzle & rain
    if (code >= 71 && code <= 77) return WeatherCondition.snowy; // snow
    if (code >= 80 && code <= 82) return WeatherCondition.rainy; // rain showers
    if (code >= 85 && code <= 86) return WeatherCondition.snowy; // snow showers
    if (code >= 95 && code <= 99) return WeatherCondition.stormy; // thunderstorm
    return WeatherCondition.cloudy;
  }

  String _wmoDescription(int code) {
    return switch (code) {
      0 => 'Clear sky',
      1 => 'Mainly clear',
      2 => 'Partly cloudy',
      3 => 'Overcast',
      45 => 'Foggy',
      48 => 'Depositing rime fog',
      51 => 'Light drizzle',
      53 => 'Moderate drizzle',
      55 => 'Dense drizzle',
      56 => 'Light freezing drizzle',
      57 => 'Dense freezing drizzle',
      61 => 'Slight rain',
      63 => 'Moderate rain',
      65 => 'Heavy rain',
      66 => 'Light freezing rain',
      67 => 'Heavy freezing rain',
      71 => 'Slight snowfall',
      73 => 'Moderate snowfall',
      75 => 'Heavy snowfall',
      77 => 'Snow grains',
      80 => 'Slight rain showers',
      81 => 'Moderate rain showers',
      82 => 'Violent rain showers',
      85 => 'Slight snow showers',
      86 => 'Heavy snow showers',
      95 => 'Thunderstorm',
      96 => 'Thunderstorm with slight hail',
      99 => 'Thunderstorm with heavy hail',
      _ => 'Unknown',
    };
  }
}
