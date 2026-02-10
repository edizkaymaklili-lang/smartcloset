import '../../../core/enums/outfit_occasion.dart';
import '../../../core/enums/weather_condition.dart';
import '../domain/entities/outfit_recommendation.dart';

class MakeupAdvisor {
  MakeupRecommendation recommend(WeatherClass weatherClass, OutfitOccasion occasion) {
    return switch ((weatherClass, occasion)) {
      // ===== HOT & SUNNY =====
      (WeatherClass.hotSunny, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'Tinted moisturizer with SPF 30+ or light BB cream',
        lips: 'Tinted lip balm or clear gloss',
        eyes: 'Light mascara, skip eyeshadow',
        tip: 'Keep it minimal — just protect and hydrate. No-makeup look is perfect for hot days.',
      ),
      (WeatherClass.hotSunny, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Lightweight foundation SPF 20, oil-control primer',
        lips: 'Coral or warm nude lipstick',
        eyes: 'Nude eyeshadow, black mascara, subtle liner',
        tip: 'Blotting papers in your bag — keep shine under control throughout the day.',
      ),
      (WeatherClass.hotSunny, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Buildable coverage with luminizing drops',
        lips: 'Bold coral, tangerine, or glossy red',
        eyes: 'Bronze shimmer lid, bold lashes or lash extensions',
        tip: 'Glow up! A golden highlighter on cheekbones perfects the summer night look.',
      ),

      // ===== MILD & WARM =====
      (WeatherClass.mildWarm, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'Light coverage tinted moisturizer',
        lips: 'Soft nude or peachy lip gloss',
        eyes: 'Curled lashes with brown mascara',
        tip: 'Dewy skin + glossy lip = effortless everyday charm.',
      ),
      (WeatherClass.mildWarm, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Satin-finish lightweight foundation',
        lips: 'Soft pink or dusty rose lipstick',
        eyes: 'Light shimmer eyeshadow, brown mascara, defined brows',
        tip: 'Perfect weather for a fresh polished look. A groomed brow makes all the difference.',
      ),
      (WeatherClass.mildWarm, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Medium coverage with luminizing finish',
        lips: 'Deep rose, mauve, or bold raspberry',
        eyes: 'Warm amber smoky eye, volumizing mascara',
        tip: 'Layer a gold shimmer over a matte base for that radiant evening glow.',
      ),

      // ===== COOL =====
      (WeatherClass.cool, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'CC cream with moisturizer base',
        lips: 'Berry gloss or tinted balm',
        eyes: 'Natural curl, brown mascara',
        tip: 'Hydrating primer keeps skin plump in cool weather. Keep the rest relaxed.',
      ),
      (WeatherClass.cool, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Medium-coverage moisturizing foundation',
        lips: 'Mauve or dusty pink matte lipstick',
        eyes: 'Warm copper and bronze eyeshadow, smudge-proof liner',
        tip: 'A hydrating primer underneath gives a smooth, all-day base.',
      ),
      (WeatherClass.cool, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Full-coverage porcelain base',
        lips: 'Classic red or deep burgundy',
        eyes: 'Intense smoky eye with charcoal and copper tones',
        tip: 'Red lip + smoky eye = timeless evening statement. Pick one to be the hero.',
      ),

      // ===== WINDY & COOL =====
      (WeatherClass.windyCool, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'Hydrating BB cream, skip powder',
        lips: 'Nourishing tinted lip balm',
        eyes: 'Mascara only — wind will smudge anything else',
        tip: 'Wind dries skin fast. A facial mist mid-day helps refresh your look.',
      ),
      (WeatherClass.windyCool, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Moisturizer-based foundation, dewy finish',
        lips: 'Rose or mauve matte lip',
        eyes: 'Warm toned shadow, smudge-proof liner, setting spray over all',
        tip: 'Use setting spray as a final step — it anchors makeup against wind.',
      ),
      (WeatherClass.windyCool, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Long-wear matte foundation, primer',
        lips: 'Wine or plum matte lip',
        eyes: 'Dramatic liner with warm brown shadows',
        tip: 'Waterproof everything. Opt for a sleek updo — loose hair in wind is a challenge!',
      ),

      // ===== RAINY =====
      (WeatherClass.rainy, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'Minimal — moisturizer + light BB cream only',
        lips: 'Long-wear lip stain',
        eyes: 'Waterproof mascara, skip shadow',
        tip: 'Less is more on rainy days. Waterproof mascara is non-negotiable.',
      ),
      (WeatherClass.rainy, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Long-lasting matte foundation + waterproof setting spray',
        lips: 'Classic red or deep berry matte lipstick',
        eyes: 'Waterproof mascara and liner only',
        tip: 'Set everything with a fixing spray. Pack a lip touch-up for the day.',
      ),
      (WeatherClass.rainy, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Porcelain matte long-wear base',
        lips: 'Deep plum or dark cherry matte lip',
        eyes: 'Dark smoky eye with waterproof formulas only',
        tip: 'Gothic glam moment — dark and moody is the vibe for a rainy evening out.',
      ),

      // ===== SNOWY & COLD =====
      (WeatherClass.snowyCold, OutfitOccasion.casual) => const MakeupRecommendation(
        foundation: 'Rich hydrating cream foundation',
        lips: 'Soft pink nourishing lipstick',
        eyes: 'Mascara + simple liner',
        tip: 'Thick moisturizer as base — cold strips skin moisture. Keep it warm and cozy.',
      ),
      (WeatherClass.snowyCold, OutfitOccasion.office) => const MakeupRecommendation(
        foundation: 'Luminous hydrating foundation',
        lips: 'Berry or deep rose lipstick',
        eyes: 'Smoky bronze or chocolate eyeshadow, defined lashes',
        tip: 'Bold lips brighten winter days. Go for warmth in both palette and color choice.',
      ),
      (WeatherClass.snowyCold, OutfitOccasion.night) => const MakeupRecommendation(
        foundation: 'Rich full-coverage luminous base',
        lips: 'Bold red, deep berry, or oxblood',
        eyes: 'Silver or gold glitter eye, dramatic lashes',
        tip: 'Winter glam — let your eyes sparkle like snow. Highlighter on inner corners!',
      ),
    };
  }
}
