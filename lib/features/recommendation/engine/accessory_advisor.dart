import '../../../core/enums/outfit_occasion.dart';
import '../../../core/enums/weather_condition.dart';

class AccessoryAdvisor {
  List<String> recommend(WeatherClass weatherClass, OutfitOccasion occasion) {
    return switch ((weatherClass, occasion)) {
      // ===== HOT & SUNNY =====
      (WeatherClass.hotSunny, OutfitOccasion.casual) => const [
        'Mini gold hoop earrings',
        'Delicate anklet',
        'Oversized sunglasses',
        'Canvas tote bag',
      ],
      (WeatherClass.hotSunny, OutfitOccasion.office) => const [
        'Gold chain necklace',
        'Simple stud earrings',
        'Classic watch',
        'Structured work tote',
      ],
      (WeatherClass.hotSunny, OutfitOccasion.night) => const [
        'Layered gold necklaces',
        'Chandelier drop earrings',
        'Beaded anklet',
        'Embellished evening bag',
      ],

      // ===== MILD & WARM =====
      (WeatherClass.mildWarm, OutfitOccasion.casual) => const [
        'Simple stud earrings',
        'Thin gold bracelet',
        'Lightweight crossbody bag',
        'Light silk scarf (optional)',
      ],
      (WeatherClass.mildWarm, OutfitOccasion.office) => const [
        'Pearl or gold button earrings',
        'Dainty pendant necklace',
        'Classic wristwatch',
        'Structured leather handbag',
      ],
      (WeatherClass.mildWarm, OutfitOccasion.night) => const [
        'Statement necklace',
        'Sparkly drop earrings',
        'Cocktail ring',
        'Satin or beaded clutch',
      ],

      // ===== COOL =====
      (WeatherClass.cool, OutfitOccasion.casual) => const [
        'Small hoop earrings',
        'Thin knit scarf',
        'Leather backpack or tote',
        'Simple cuff bracelet',
      ],
      (WeatherClass.cool, OutfitOccasion.office) => const [
        'Statement earrings',
        'Silk or wool scarf',
        'Leather belt',
        'Professional structured bag',
      ],
      (WeatherClass.cool, OutfitOccasion.night) => const [
        'Vintage brooch on lapel',
        'Chandelier crystal earrings',
        'Velvet or suede clutch',
        'Cocktail ring',
      ],

      // ===== WINDY & COOL =====
      (WeatherClass.windyCool, OutfitOccasion.casual) => const [
        'Stud earrings (won\'t tangle)',
        'Lightweight scarf or shawl',
        'Secure zip crossbody bag',
        'Simple bracelet',
      ],
      (WeatherClass.windyCool, OutfitOccasion.office) => const [
        'Huggie earrings (stay in place)',
        'Cashmere wool shawl',
        'Structured work bag with clasp',
        'Slim wristwatch',
      ],
      (WeatherClass.windyCool, OutfitOccasion.night) => const [
        'Elegant drop earrings (not too long)',
        'Wrap or pashmina shawl',
        'Sleek evening bag with handle',
        'Statement cocktail ring',
      ],

      // ===== RAINY =====
      (WeatherClass.rainy, OutfitOccasion.casual) => const [
        'Small stud earrings',
        'Compact foldable umbrella',
        'Waterproof backpack or tote',
        'Rubber or silicone bracelet',
      ],
      (WeatherClass.rainy, OutfitOccasion.office) => const [
        'Classic gold or silver studs',
        'Compact quality umbrella',
        'Water-resistant work bag',
        'Stainless steel watch',
      ],
      (WeatherClass.rainy, OutfitOccasion.night) => const [
        'Drop earrings (no dangling chains)',
        'Long chain necklace',
        'Sleek waterproof evening bag',
        'Stainless steel or resin ring',
      ],

      // ===== SNOWY & COLD =====
      (WeatherClass.snowyCold, OutfitOccasion.casual) => const [
        'Chunky knit beanie',
        'Soft wool gloves',
        'Cozy long scarf',
        'Casual tote bag',
      ],
      (WeatherClass.snowyCold, OutfitOccasion.office) => const [
        'Classic pearl stud earrings',
        'Leather or suede gloves',
        'Sophisticated winter bag',
        'Slim gold or silver watch',
      ],
      (WeatherClass.snowyCold, OutfitOccasion.night) => const [
        'Crystal or diamond drop earrings',
        'Faux fur stole or wrap',
        'Velvet or embellished clutch',
        'Layered bracelets or cuff',
      ],
    };
  }
}
