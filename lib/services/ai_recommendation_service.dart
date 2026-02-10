import 'package:cloud_functions/cloud_functions.dart';
import '../core/enums/clothing_category.dart';
import '../core/enums/outfit_occasion.dart';
import '../features/recommendation/domain/entities/outfit_recommendation.dart';
import '../features/wardrobe/domain/entities/clothing_item.dart';
import '../features/weather/domain/entities/weather_data.dart';
import '../features/profile/domain/entities/user_profile.dart';

class AiRecommendationService {
  final FirebaseFunctions _functions;

  AiRecommendationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<OutfitRecommendation> generateRecommendation({
    required WeatherData weather,
    required UserProfile profile,
    required List<ClothingItem> wardrobe,
  }) async {
    final callable = _functions.httpsCallable('getOutfitRecommendation');

    final result = await callable.call<Map<String, dynamic>>({
      'temperature': weather.temperature,
      'feelsLike': weather.feelsLike,
      'humidity': weather.humidity,
      'windSpeed': weather.windSpeed,
      'precipitation': weather.precipitation,
      'weatherDescription': weather.description,
      'city': profile.city,
      'stylePreference': profile.stylePreference.name,
      'bodyType': profile.bodyType?.name,
      'heightRange': profile.heightRange?.name,
      'workType': profile.workType?.name,
      'hobbies': profile.hobbies.map((h) => h.name).toList(),
      'colorSeason': profile.colorSeason?.name,
      'bestColors': profile.colorSeason?.bestColors ?? [],
      'avoidColors': profile.colorSeason?.avoidColors ?? [],
      'bodyTypeStyles': profile.bodyType?.recommendedStyles ?? [],
      'wardrobeItems': wardrobe
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'category': item.category.name,
                'color': item.color,
                'seasons': item.seasons,
                'occasions': item.occasions,
                'weatherSuitability': item.weatherSuitability,
              })
          .toList(),
    });

    return _parseResponse(result.data);
  }

  OutfitRecommendation _parseResponse(Map<String, dynamic> data) {
    final occasionsRaw = data['occasions'] as Map<String, dynamic>;
    final occasions = <OutfitOccasion, OccasionOutfit>{};

    for (final entry in occasionsRaw.entries) {
      final occasion = OutfitOccasion.values.firstWhere(
        (o) => o.name == entry.key,
        orElse: () => OutfitOccasion.casual,
      );
      occasions[occasion] = _parseOccasionOutfit(
        entry.value as Map<String, dynamic>,
      );
    }

    final smartTips = (data['smartTips'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return OutfitRecommendation(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      occasions: occasions,
      smartTips: smartTips,
    );
  }

  OccasionOutfit _parseOccasionOutfit(Map<String, dynamic> data) {
    final itemsList = (data['items'] as List?) ?? [];
    final items = itemsList.map((item) {
      final m = item as Map<String, dynamic>;
      return OutfitItem(
        category: ClothingCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => ClothingCategory.tops,
        ),
        description: m['description'] as String? ?? '',
        wardrobeItemId: m['wardrobeItemId'] as String?,
      );
    }).toList();

    final makeupRaw = data['makeup'] as Map<String, dynamic>? ?? {};
    final makeup = MakeupRecommendation(
      foundation: makeupRaw['foundation'] as String? ?? '',
      lips: makeupRaw['lips'] as String? ?? '',
      eyes: makeupRaw['eyes'] as String? ?? '',
      tip: makeupRaw['tip'] as String? ?? '',
    );

    final accessories = (data['accessories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return OccasionOutfit(
      items: items,
      makeup: makeup,
      accessories: accessories,
      smartTip: data['smartTip'] as String?,
    );
  }
}
