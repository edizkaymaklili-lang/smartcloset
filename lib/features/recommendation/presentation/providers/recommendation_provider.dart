import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/outfit_occasion.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../../engine/recommendation_engine.dart';
import '../../domain/entities/outfit_recommendation.dart';
import '../../../../main.dart' show firebaseAvailableProvider;
import '../../../../services/ai_recommendation_service.dart';

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

final aiRecommendationServiceProvider = Provider<AiRecommendationService>((ref) {
  return AiRecommendationService();
});

/// AsyncNotifier — tries Gemini AI first, silently falls back to rule matrix.
final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, OutfitRecommendation>(
  RecommendationNotifier.new,
);

class RecommendationNotifier extends AsyncNotifier<OutfitRecommendation> {
  @override
  Future<OutfitRecommendation> build() async {
    final weatherAsync = ref.watch(weatherProvider);
    final profile = ref.watch(profileProvider);
    final wardrobe = ref.watch(wardrobeProvider);
    final firebaseReady = ref.watch(firebaseAvailableProvider);

    final weather = await weatherAsync.when(
      data: (w) async => w,
      loading: () => Future<dynamic>.error('loading'),
      error: (e, st) => Future<dynamic>.error(e),
    );

    // Try AI if Firebase is ready
    if (firebaseReady) {
      try {
        final aiService = ref.read(aiRecommendationServiceProvider);
        return await aiService.generateRecommendation(
          weather: weather,
          profile: profile,
          wardrobe: wardrobe,
        );
      } catch (_) {
        // AI failed — fall back to local rule matrix silently
      }
    }

    // Local rule matrix fallback
    final engine = ref.read(recommendationEngineProvider);
    return engine.generateDailyRecommendation(
      weather: weather,
      stylePreference: profile.stylePreference,
      wardrobe: wardrobe,
      profile: profile,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  /// Regenerate outfit for a specific occasion while keeping others unchanged
  Future<void> regenerateOccasion(OutfitOccasion occasion) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    state = const AsyncValue.loading();

    try {
      final weatherAsync = ref.read(weatherProvider);
      final profile = ref.read(profileProvider);
      final wardrobe = ref.read(wardrobeProvider);
      final engine = ref.read(recommendationEngineProvider);

      final weather = await weatherAsync.when(
        data: (w) async => w,
        loading: () => Future<dynamic>.error('loading'),
        error: (e, st) => Future<dynamic>.error(e),
      );

      // Generate new full recommendation
      final newRecommendation = engine.generateDailyRecommendation(
        weather: weather,
        stylePreference: profile.stylePreference,
        wardrobe: wardrobe,
        profile: profile,
      );

      // Copy old recommendation but replace the specific occasion
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
