import 'dart:math';
import '../../../../core/enums/weather_condition.dart';
import '../../domain/entities/weather_data.dart';

class WeatherMockDatasource {
  final _random = Random();

  final List<_MockScenario> _scenarios = const [
    _MockScenario(
      condition: WeatherCondition.sunny,
      tempRange: (27, 35),
      humidity: 35,
      windSpeed: 2.5,
      precipitation: 0,
      description: 'Clear sky, bright sunshine',
    ),
    _MockScenario(
      condition: WeatherCondition.rainy,
      tempRange: (12, 18),
      humidity: 85,
      windSpeed: 4.0,
      precipitation: 8.5,
      description: 'Light to moderate rain expected',
    ),
    _MockScenario(
      condition: WeatherCondition.windy,
      tempRange: (14, 20),
      humidity: 50,
      windSpeed: 9.5,
      precipitation: 0.5,
      description: 'Strong winds with cool breeze',
    ),
    _MockScenario(
      condition: WeatherCondition.snowy,
      tempRange: (-3, 4),
      humidity: 75,
      windSpeed: 3.0,
      precipitation: 12.0,
      description: 'Snow showers throughout the day',
    ),
    _MockScenario(
      condition: WeatherCondition.cloudy,
      tempRange: (18, 24),
      humidity: 60,
      windSpeed: 3.5,
      precipitation: 1.0,
      description: 'Partly cloudy with mild temperatures',
    ),
  ];

  WeatherData getCurrentWeather({String city = 'Istanbul'}) {
    // Use hour of day to cycle through scenarios for variety
    final hour = DateTime.now().hour;
    final scenarioIndex = hour % _scenarios.length;
    final scenario = _scenarios[scenarioIndex];

    final temp = scenario.tempRange.$1 +
        _random.nextDouble() * (scenario.tempRange.$2 - scenario.tempRange.$1);

    return WeatherData(
      temperature: double.parse(temp.toStringAsFixed(1)),
      feelsLike: double.parse((temp - 2 + _random.nextDouble() * 4).toStringAsFixed(1)),
      humidity: scenario.humidity + _random.nextInt(10) - 5,
      windSpeed: scenario.windSpeed + _random.nextDouble() * 2,
      precipitation: scenario.precipitation,
      description: scenario.description,
      condition: scenario.condition,
      cityName: city,
      timestamp: DateTime.now(),
      hourlyForecast: _generateHourlyForecast(scenario),
    );
  }

  List<HourlyForecast> _generateHourlyForecast(_MockScenario baseScenario) {
    final now = DateTime.now();
    return List.generate(24, (i) {
      final hour = now.add(Duration(hours: i));
      final tempVariation = sin(i * 0.3) * 4;
      final baseTemp = (baseScenario.tempRange.$1 + baseScenario.tempRange.$2) / 2;

      // Simulate afternoon rain possibility
      final hasAfternoonRain = i >= 6 && i <= 12 && baseScenario.precipitation > 0;

      return HourlyForecast(
        time: hour,
        temperature: double.parse((baseTemp + tempVariation).toStringAsFixed(1)),
        condition: hasAfternoonRain ? WeatherCondition.rainy : baseScenario.condition,
        precipitationProbability: hasAfternoonRain ? 0.7 : baseScenario.precipitation > 0 ? 0.3 : 0.05,
      );
    });
  }
}

class _MockScenario {
  final WeatherCondition condition;
  final (int, int) tempRange;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final String description;

  const _MockScenario({
    required this.condition,
    required this.tempRange,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.description,
  });
}
