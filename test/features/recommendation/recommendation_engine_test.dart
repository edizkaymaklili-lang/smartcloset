import 'package:flutter_test/flutter_test.dart';
import 'package:stil_asist/core/enums/outfit_occasion.dart';
import 'package:stil_asist/core/enums/style_preference.dart';
import 'package:stil_asist/core/enums/weather_condition.dart';
import 'package:stil_asist/features/recommendation/engine/recommendation_engine.dart';
import 'package:stil_asist/features/recommendation/engine/weather_classifier.dart';
import 'package:stil_asist/features/weather/domain/entities/weather_data.dart';

WeatherData _weather({
  double temp = 20,
  double wind = 3,
  double precip = 0,
  int humidity = 50,
  WeatherCondition condition = WeatherCondition.sunny,
}) {
  return WeatherData(
    temperature: temp,
    feelsLike: temp - 1,
    humidity: humidity,
    windSpeed: wind,
    precipitation: precip,
    description: 'test',
    condition: condition,
    cityName: 'TestCity',
    timestamp: DateTime(2024, 7, 15, 10),
  );
}

void main() {
  group('WeatherClassifier', () {
    late WeatherClassifier classifier;

    setUp(() => classifier = WeatherClassifier());

    test('classifies snowy condition as snowyCold', () {
      final result = classifier.classify(_weather(condition: WeatherCondition.snowy));
      expect(result, WeatherClass.snowyCold);
    });

    test('classifies temperature <= 5 as snowyCold', () {
      final result = classifier.classify(_weather(temp: 4));
      expect(result, WeatherClass.snowyCold);
    });

    test('classifies rainy condition as rainy', () {
      final result = classifier.classify(_weather(condition: WeatherCondition.rainy, temp: 18));
      expect(result, WeatherClass.rainy);
    });

    test('classifies high precipitation as rainy', () {
      final result = classifier.classify(_weather(precip: 6, temp: 18));
      expect(result, WeatherClass.rainy);
    });

    test('classifies windy and cool as windyCool', () {
      final result = classifier.classify(_weather(wind: 10, temp: 14));
      expect(result, WeatherClass.windyCool);
    });

    test('classifies hot sunny day as hotSunny', () {
      final result = classifier.classify(_weather(temp: 28));
      expect(result, WeatherClass.hotSunny);
    });

    test('classifies mild temperature as mildWarm', () {
      final result = classifier.classify(_weather(temp: 21));
      expect(result, WeatherClass.mildWarm);
    });

    test('classifies cool (6-17°C) as cool', () {
      final result = classifier.classify(_weather(temp: 12));
      expect(result, WeatherClass.cool);
    });
  });

  group('RecommendationEngine', () {
    late RecommendationEngine engine;

    setUp(() => engine = RecommendationEngine());

    test('generates recommendations for all occasions', () {
      final rec = engine.generateDailyRecommendation(
        weather: _weather(temp: 20),
        stylePreference: StylePreference.sporty,
      );

      expect(rec.occasions, isNotEmpty);
      for (final occasion in OutfitOccasion.values) {
        expect(rec.occasions.containsKey(occasion), isTrue,
            reason: 'Missing occasion: ${occasion.name}');
      }
    });

    test('each occasion outfit has at least one item', () {
      final rec = engine.generateDailyRecommendation(
        weather: _weather(temp: 20),
        stylePreference: StylePreference.classic,
      );

      for (final entry in rec.occasions.entries) {
        expect(entry.value.items, isNotEmpty,
            reason: '${entry.key.name} has no items');
      }
    });

    test('empty wardrobe produces generic items (no wardrobeItemId)', () {
      final rec = engine.generateDailyRecommendation(
        weather: _weather(temp: 22),
        stylePreference: StylePreference.sporty,
        wardrobe: [],
      );

      for (final outfit in rec.occasions.values) {
        for (final item in outfit.items) {
          expect(item.wardrobeItemId, isNull,
              reason: 'Generic item should have no wardrobeItemId');
        }
      }
    });

    test('generates smart tip for high humidity', () {
      final rec = engine.generateDailyRecommendation(
        weather: _weather(temp: 20, humidity: 90),
        stylePreference: StylePreference.sporty,
      );
      expect(rec.smartTips, isNotEmpty);
      expect(
        rec.smartTips.any((t) => t.toLowerCase().contains('humid')),
        isTrue,
      );
    });

    test('generates smart tip for afternoon rain in hourly forecast', () {
      final now = DateTime.now();
      final forecastWithAfternoonRain = [
        HourlyForecast(
          time: DateTime(now.year, now.month, now.day, 14),
          temperature: 18,
          condition: WeatherCondition.rainy,
          precipitationProbability: 0.8,
        ),
      ];
      final weather = WeatherData(
        temperature: 18,
        feelsLike: 17,
        humidity: 60,
        windSpeed: 3,
        precipitation: 0,
        description: 'Partly cloudy',
        condition: WeatherCondition.cloudy,
        cityName: 'TestCity',
        timestamp: DateTime(now.year, now.month, now.day, 8),
        hourlyForecast: forecastWithAfternoonRain,
      );
      final rec = engine.generateDailyRecommendation(
        weather: weather,
        stylePreference: StylePreference.sporty,
      );
      expect(
        rec.smartTips.any((t) => t.toLowerCase().contains('afternoon')),
        isTrue,
      );
    });

    test('recommendation id is based on weather timestamp', () {
      final weather = _weather(temp: 20);
      final rec = engine.generateDailyRecommendation(
        weather: weather,
        stylePreference: StylePreference.sporty,
      );
      expect(rec.id, '${weather.timestamp.millisecondsSinceEpoch}');
    });
  });
}
