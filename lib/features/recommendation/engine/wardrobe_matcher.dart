import '../domain/entities/outfit_recommendation.dart';
import '../../wardrobe/domain/entities/clothing_item.dart';

class WardrobeMatcher {
  /// Attempts to match a generic OutfitItem to a ClothingItem from the user's
  /// wardrobe. Returns the original item if no match is found.
  OutfitItem matchItem({
    required OutfitItem generic,
    required List<ClothingItem> wardrobe,
    required String occasion,
    required String weatherSuitability,
  }) {
    // Filter candidates by category
    final candidates = wardrobe.where((c) => c.category == generic.category).toList();
    if (candidates.isEmpty) return generic;

    // Score each candidate
    final scored = candidates.map((c) {
      int score = 0;
      if (c.occasions.contains(occasion)) score += 3;
      if (c.weatherSuitability.contains(weatherSuitability)) score += 2;
      if (c.isFavorite) score += 1;
      // Prefer items not worn recently
      if (c.lastWorn == null) {
        score += 2;
      } else {
        final daysSince = DateTime.now().difference(c.lastWorn!).inDays;
        if (daysSince > 7) score += 1;
      }
      return (item: c, score: score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    final best = scored.first.item;
    return OutfitItem(
      category: best.category,
      description: best.name,
      imageUrl: best.effectiveImagePath,
      wardrobeItemId: best.id,
    );
  }

  /// Matches all items in an OccasionOutfit to wardrobe items where possible.
  OccasionOutfit matchOccasionOutfit({
    required OccasionOutfit outfit,
    required List<ClothingItem> wardrobe,
    required String occasion,
    required String weatherSuitability,
  }) {
    final matchedItems = outfit.items.map((item) {
      return matchItem(
        generic: item,
        wardrobe: wardrobe,
        occasion: occasion,
        weatherSuitability: weatherSuitability,
      );
    }).toList();

    return OccasionOutfit(
      items: matchedItems,
      makeup: outfit.makeup,
      accessories: outfit.accessories,
      smartTip: outfit.smartTip,
    );
  }
}
