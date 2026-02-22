import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/outfit_occasion.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../../engine/recommendation_engine.dart';
import '../../domain/entities/outfit_recommendation.dart';

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, OutfitRecommendation>(
  RecommendationNotifier.new,
);

class RecommendationNotifier extends AsyncNotifier<OutfitRecommendation> {
  @override
  Future<OutfitRecommendation> build() async {
    // Keep recommendations cached - don't recalculate when navigating away
    ref.keepAlive();

    final profile = ref.watch(profileProvider);
    final wardrobe = ref.watch(wardrobeProvider);

    // Await weather data - Riverpod handles loading/error states automatically
    final weather = await ref.watch(weatherProvider.future);
    final engine = ref.read(recommendationEngineProvider);
    return engine.generateDailyRecommendation(
      weather: weather,
      stylePreference: profile.stylePreference,
      wardrobe: wardrobe,
      profile: profile,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  Future<void> regenerateOccasion(OutfitOccasion occasion) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    state = const AsyncValue.loading();

    try {
      final weatherAsync = ref.read(weatherProvider);
      if (!weatherAsync.hasValue) throw Exception('Weather not available');

      final profile = ref.read(profileProvider);
      final wardrobe = ref.read(wardrobeProvider);
      final engine = ref.read(recommendationEngineProvider);
      final weather = weatherAsync.value!;

      final newRecommendation = engine.generateDailyRecommendation(
        weather: weather,
        stylePreference: profile.stylePreference,
        wardrobe: wardrobe,
        profile: profile,
      );

      final updatedOccasions = Map<OutfitOccasion, OccasionOutfit>.from(
        currentState.value!.occasions,
      );
      updatedOccasions[occasion] = newRecommendation.occasions[occasion]!;

      final updatedRecommendation = OutfitRecommendation(
        id: currentState.value!.id,
        date: currentState.value!.date,
        occasions: updatedOccasions,
        smartTips: currentState.value!.smartTips,
      );

      state = AsyncValue.data(updatedRecommendation);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
