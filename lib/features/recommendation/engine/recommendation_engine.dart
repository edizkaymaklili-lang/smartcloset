import 'dart:math';
import '../../../core/enums/outfit_occasion.dart';
import '../../../core/enums/style_preference.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../wardrobe/domain/entities/clothing_item.dart';
import '../../weather/domain/entities/weather_data.dart';
import '../domain/entities/outfit_recommendation.dart';
import 'weather_classifier.dart';
import 'outfit_rule_matrix.dart';
import 'makeup_advisor.dart';
import 'accessory_advisor.dart';
import 'wardrobe_matcher.dart';

class RecommendationEngine {
  final WeatherClassifier _weatherClassifier = WeatherClassifier();
  final OutfitRuleMatrix _outfitRuleMatrix = OutfitRuleMatrix();
  final MakeupAdvisor _makeupAdvisor = MakeupAdvisor();
  final AccessoryAdvisor _accessoryAdvisor = AccessoryAdvisor();
  final WardrobeMatcher _wardrobeMatcher = WardrobeMatcher();

  OutfitRecommendation generateDailyRecommendation({
    required WeatherData weather,
    required StylePreference stylePreference,
    List<ClothingItem> wardrobe = const [],
    UserProfile? profile,
  }) {
    // Step 1: Classify weather
    final weatherClass = _weatherClassifier.classify(weather);
    final weatherSuitability = _weatherSuitabilityLabel(weather);

    // Step 2: Generate outfit for each occasion with occasion-specific makeup & accessories
    final occasions = <OutfitOccasion, OccasionOutfit>{};
    for (final occasion in OutfitOccasion.values) {
      final makeup = _makeupAdvisor.recommend(weatherClass, occasion);
      final accessories = _accessoryAdvisor.recommend(weatherClass, occasion);
      final generic = _outfitRuleMatrix.generate(
        weatherClass: weatherClass,
        occasion: occasion,
        style: stylePreference,
        accessories: accessories,
        makeup: makeup,
      );
      occasions[occasion] = wardrobe.isEmpty
          ? generic
          : _wardrobeMatcher.matchOccasionOutfit(
              outfit: generic,
              wardrobe: wardrobe,
              occasion: occasion.name,
              weatherSuitability: weatherSuitability,
            );
    }

    // Step 4: Generate smart tips (including personalization)
    final smartTips = _generateSmartTips(weather);
    if (profile != null) {
      smartTips.addAll(_generatePersonalizedTips(profile));
    }

    return OutfitRecommendation(
      id: '${weather.timestamp.millisecondsSinceEpoch}',
      date: weather.timestamp,
      occasions: occasions,
      smartTips: smartTips,
    );
  }

  String _weatherSuitabilityLabel(WeatherData weather) {
    if (weather.precipitation > 2) return 'rainy';
    if (weather.windSpeed > 8) return 'windy';
    if (weather.temperature >= 25) return 'hot';
    if (weather.temperature >= 15) return 'mild';
    if (weather.temperature >= 5) return 'cool';
    return 'cold';
  }

  List<String> _generateSmartTips(WeatherData weather) {
    final tips = <String>[];

    // Check afternoon rain from hourly forecast
    if (weather.hourlyForecast.isNotEmpty) {
      final afternoonRain = weather.hourlyForecast
          .where((h) => h.time.hour >= 12 && h.time.hour <= 18)
          .any((h) => h.precipitationProbability > 0.5);
      if (afternoonRain) {
        tips.add('Rain expected in the afternoon — pack a foldable umbrella!');
      }

      // Check morning rain
      final morningRain = weather.hourlyForecast
          .where((h) => h.time.hour >= 6 && h.time.hour <= 11)
          .any((h) => h.precipitationProbability > 0.5);
      if (morningRain && !afternoonRain) {
        tips.add('Morning rain expected — wear waterproof shoes for your commute.');
      }

      // Check evening temperature drop
      final eveningTemps = weather.hourlyForecast
          .where((h) => h.time.hour >= 18)
          .map((h) => h.temperature);
      if (eveningTemps.isNotEmpty) {
        final tempDrop = weather.temperature - eveningTemps.reduce(min);
        if (tempDrop > 8) {
          tips.add('Temperature will drop ${tempDrop.toStringAsFixed(0)}°C by evening — bring a light jacket.');
        } else if (tempDrop > 5) {
          tips.add('Slight temperature drop expected in the evening — consider a cardigan.');
        }
      }

      // Check for temperature rise (cold morning, warm afternoon)
      final morningTemps = weather.hourlyForecast
          .where((h) => h.time.hour >= 6 && h.time.hour <= 9)
          .map((h) => h.temperature);
      if (morningTemps.isNotEmpty) {
        final tempRise = weather.temperature - morningTemps.reduce(min);
        if (tempRise > 10) {
          tips.add('Cold morning but warming up later — layer up so you can remove pieces.');
        }
      }
    }

    // Humidity tips with detailed advice
    if (weather.humidity > 85) {
      tips.add('Very high humidity today — wear moisture-wicking fabrics like cotton or linen.');
    } else if (weather.humidity > 70) {
      tips.add('High humidity today — choose breathable, light fabrics.');
    } else if (weather.humidity < 30) {
      tips.add('Low humidity today — moisturize your skin and lips regularly.');
    }

    // Temperature-specific clothing advice
    if (weather.temperature > 32) {
      tips.add('Very hot weather — wear light colors, loose fits, and stay hydrated!');
    } else if (weather.temperature > 28 && weather.precipitation < 1) {
      tips.add('UV index is high — wear a hat and apply sunscreen generously!');
    } else if (weather.temperature < -5) {
      tips.add('Extreme cold — wear insulated layers, gloves, and a warm hat.');
    } else if (weather.temperature < 3) {
      tips.add('Freezing temperatures — layer up with thermal innerwear.');
    } else if (weather.temperature >= 15 && weather.temperature <= 22) {
      tips.add('Perfect temperature for layering — great day for your favorite jacket!');
    }

    // Wind tips with intensity levels
    if (weather.windSpeed > 12) {
      tips.add('Very strong winds — secure your hair, avoid umbrellas, and wear fitted clothing.');
    } else if (weather.windSpeed > 8) {
      tips.add('Strong winds expected — avoid loose scarves and flowy dresses.');
    } else if (weather.windSpeed > 5) {
      tips.add('Breezy today — light layers recommended for comfort.');
    }

    // Precipitation tips
    if (weather.precipitation > 5) {
      tips.add('Heavy rain expected — waterproof everything and avoid suede or leather shoes.');
    } else if (weather.precipitation > 2) {
      tips.add('Moderate rain — pack a rain jacket and choose quick-dry fabrics.');
    }

    // Combination conditions
    if (weather.temperature < 10 && weather.windSpeed > 5) {
      tips.add('Cold and windy — windchill makes it feel colder, add a windbreaker layer.');
    }

    if (weather.temperature > 25 && weather.humidity > 70) {
      tips.add('Hot and humid — avoid synthetic fabrics that trap heat and moisture.');
    }

    return tips;
  }

  /// Generate personalized tips based on user profile
  List<String> _generatePersonalizedTips(UserProfile profile) {
    final tips = <String>[];

    // Body type tips
    if (profile.bodyType != null) {
      final styles = profile.bodyType!.recommendedStyles;
      if (styles.isNotEmpty) {
        tips.add('For ${profile.bodyType!.displayName} body type: ${styles.first}');
      }
    }

    // Height tips
    if (profile.heightRange != null) {
      final heightTips = profile.heightRange!.styleTips;
      if (heightTips.isNotEmpty) {
        tips.add(heightTips.first);
      }
    }

    // Color season tips
    if (profile.colorSeason != null) {
      final colors = profile.colorSeason!.bestColors.take(3).join(', ');
      tips.add('Best colors for ${profile.colorSeason!.displayName} season: $colors');
    }

    // Active hobby reminder for sports outfit
    final activeSports = profile.hobbies.where((h) => h.isActiveSport).toList();
    if (activeSports.isNotEmpty) {
      tips.add('Planning ${activeSports.first.displayName}? ${activeSports.first.outfitHint}');
    }

    return tips;
  }
}
