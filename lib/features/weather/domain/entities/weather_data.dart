import '../../../../core/enums/weather_condition.dart';

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final String description;
  final WeatherCondition condition;
  final String cityName;
  final DateTime timestamp;
  final List<HourlyForecast> hourlyForecast;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.description,
    required this.condition,
    required this.cityName,
    required this.timestamp,
    this.hourlyForecast = const [],
  });

  WeatherData copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    double? precipitation,
    String? description,
    WeatherCondition? condition,
    String? cityName,
    DateTime? timestamp,
    List<HourlyForecast>? hourlyForecast,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      precipitation: precipitation ?? this.precipitation,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      cityName: cityName ?? this.cityName,
      timestamp: timestamp ?? this.timestamp,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final WeatherCondition condition;
  final double precipitationProbability;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.precipitationProbability,
  });
}
