import '../../../core/enums/clothing_category.dart';
import '../../../core/enums/outfit_occasion.dart';
import '../../../core/enums/style_preference.dart';
import '../../../core/enums/weather_condition.dart';
import '../domain/entities/outfit_recommendation.dart';

class OutfitRuleMatrix {
  OccasionOutfit generate({
    required WeatherClass weatherClass,
    required OutfitOccasion occasion,
    required StylePreference style,
    required List<String> accessories,
    required MakeupRecommendation makeup,
  }) {
    final items = _getOutfitItems(weatherClass, occasion, style);
    return OccasionOutfit(
      items: items,
      makeup: makeup,
      accessories: accessories,
    );
  }

  List<OutfitItem> _getOutfitItems(
    WeatherClass weather,
    OutfitOccasion occasion,
    StylePreference style,
  ) {
    return switch ((weather, occasion)) {
      // ===== HOT & SUNNY =====
      (WeatherClass.hotSunny, OutfitOccasion.office) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Crisp white linen blouse'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Light-colored tailored trousers'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Nude pointed-toe flats'),
        ],
        StylePreference.sporty => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Fitted polo shirt in pastel tone'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Slim chino pants in khaki'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Clean white sneakers'),
        ],
        StylePreference.bohemian => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Embroidered cotton blouse'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Wide-leg linen pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Woven leather sandals'),
        ],
        StylePreference.elegant => const [
          OutfitItem(category: ClothingCategory.dresses, description: 'Silk midi wrap dress in soft print'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Strappy kitten heels'),
        ],
      },
      (WeatherClass.hotSunny, OutfitOccasion.casual) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Striped cotton t-shirt'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'High-waist linen shorts'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Leather slide sandals'),
        ],
        StylePreference.sporty => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Breathable tank top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Athletic shorts or skort'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Lightweight running shoes'),
        ],
        StylePreference.bohemian => const [
          OutfitItem(category: ClothingCategory.dresses, description: 'Flowy maxi sundress with floral print'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Braided flat sandals'),
        ],
        StylePreference.elegant => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Off-shoulder linen top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'High-waist palazzo pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Embellished flat sandals'),
        ],
      },
      (WeatherClass.hotSunny, OutfitOccasion.night) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.dresses, description: 'Sleeveless A-line cocktail dress'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Block heel sandals'),
        ],
        StylePreference.sporty => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Cropped satin cami top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'High-waist wide-leg jeans'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Platform sneakers'),
        ],
        StylePreference.bohemian => const [
          OutfitItem(category: ClothingCategory.dresses, description: 'Crochet midi dress with slip underneath'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Espadrille wedges'),
        ],
        StylePreference.elegant => const [
          OutfitItem(category: ClothingCategory.dresses, description: 'Satin slip dress with delicate straps'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Strappy stiletto heels'),
        ],
      },

      // ===== RAINY =====
      (WeatherClass.rainy, OutfitOccasion.office) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Beige trench coat'),
          OutfitItem(category: ClothingCategory.tops, description: 'Tucked-in silk blouse'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Dark tailored trousers'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Waterproof Chelsea boots'),
        ],
        StylePreference.sporty => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Sleek rain jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Mock-neck long sleeve top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Dark straight-leg pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Water-resistant trainers'),
        ],
        StylePreference.bohemian => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Oversized waxed cotton jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Flowy peasant blouse'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Dark wash bootcut jeans'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Leather lace-up boots'),
        ],
        StylePreference.elegant => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Belted trench coat in navy'),
          OutfitItem(category: ClothingCategory.dresses, description: 'Knit bodycon midi dress'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Pointed-toe waterproof ankle boots'),
        ],
      },
      (WeatherClass.rainy, OutfitOccasion.casual) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Lightweight rain parka'),
          OutfitItem(category: ClothingCategory.tops, description: 'Breton stripe long-sleeve tee'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Dark skinny jeans'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Rubber rain boots'),
        ],
        _ => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Hooded rain jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Comfortable long-sleeve shirt'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Dark jogger pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Waterproof sneakers'),
        ],
      },
      (WeatherClass.rainy, OutfitOccasion.night) => switch (style) {
        StylePreference.elegant => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Structured black coat'),
          OutfitItem(category: ClothingCategory.dresses, description: 'Dark satin midi dress'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Waterproof heeled ankle boots'),
        ],
        _ => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Stylish rain-resistant jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Dark blouse or top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Black slim pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Waterproof ankle boots'),
        ],
      },

      // ===== WINDY & COOL =====
      (WeatherClass.windyCool, OutfitOccasion.office) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Structured blazer'),
          OutfitItem(category: ClothingCategory.tops, description: 'Fitted turtleneck in neutral tone'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Wool-blend tailored pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Leather ankle boots'),
        ],
        _ => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Leather or suede jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Layered knit top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Sturdy trousers or jeans'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Closed-toe boots'),
        ],
      },
      (WeatherClass.windyCool, OutfitOccasion.casual) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Denim or leather jacket'),
        OutfitItem(category: ClothingCategory.tops, description: 'Cozy knit sweater'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Straight-leg jeans'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Lace-up ankle boots'),
      ],
      (WeatherClass.windyCool, OutfitOccasion.night) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Sleek moto jacket'),
        OutfitItem(category: ClothingCategory.tops, description: 'Fitted bodysuit or blouse'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'High-waist leather-look pants'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Heeled ankle boots'),
      ],

      // ===== SNOWY & COLD =====
      (WeatherClass.snowyCold, OutfitOccasion.office) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Wool overcoat in camel or charcoal'),
          OutfitItem(category: ClothingCategory.tops, description: 'Cashmere crewneck sweater'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Thick wool trousers'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Insulated leather boots'),
        ],
        _ => const [
          OutfitItem(category: ClothingCategory.outerwear, description: 'Puffer coat or down jacket'),
          OutfitItem(category: ClothingCategory.tops, description: 'Thermal base layer + warm sweater'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Fleece-lined pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Waterproof insulated boots'),
        ],
      },
      (WeatherClass.snowyCold, OutfitOccasion.casual) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Long puffer coat'),
        OutfitItem(category: ClothingCategory.tops, description: 'Chunky knit sweater over thermal layer'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Fleece-lined leggings or jeans'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Fur-lined snow boots'),
      ],
      (WeatherClass.snowyCold, OutfitOccasion.night) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Faux-fur or shearling coat'),
        OutfitItem(category: ClothingCategory.dresses, description: 'Knit midi dress with tights'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Knee-high suede boots'),
      ],

      // ===== MILD & WARM =====
      (WeatherClass.mildWarm, OutfitOccasion.office) => switch (style) {
        StylePreference.classic => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Button-down cotton shirt'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Mid-weight tailored trousers'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Leather loafers'),
        ],
        _ => const [
          OutfitItem(category: ClothingCategory.tops, description: 'Light blouse or knit top'),
          OutfitItem(category: ClothingCategory.bottoms, description: 'Comfortable dress pants'),
          OutfitItem(category: ClothingCategory.shoes, description: 'Ballet flats or loafers'),
        ],
      },
      (WeatherClass.mildWarm, OutfitOccasion.casual) => const [
        OutfitItem(category: ClothingCategory.tops, description: 'Relaxed-fit cotton t-shirt'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Light wash mom jeans'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Canvas sneakers'),
      ],
      (WeatherClass.mildWarm, OutfitOccasion.night) => const [
        OutfitItem(category: ClothingCategory.tops, description: 'Silk camisole with light cardigan'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'High-waist wide-leg trousers'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Strappy block-heel sandals'),
      ],

      // ===== COOL =====
      (WeatherClass.cool, OutfitOccasion.office) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Light cardigan or blazer'),
        OutfitItem(category: ClothingCategory.tops, description: 'Long-sleeve fitted top'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Mid-weight trousers'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Closed-toe flats or loafers'),
      ],
      (WeatherClass.cool, OutfitOccasion.casual) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Light denim jacket'),
        OutfitItem(category: ClothingCategory.tops, description: 'Soft knit sweater'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Relaxed-fit jeans'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Suede ankle boots'),
      ],
      (WeatherClass.cool, OutfitOccasion.night) => const [
        OutfitItem(category: ClothingCategory.outerwear, description: 'Cropped jacket'),
        OutfitItem(category: ClothingCategory.tops, description: 'Satin or velvet top'),
        OutfitItem(category: ClothingCategory.bottoms, description: 'Dark tailored pants'),
        OutfitItem(category: ClothingCategory.shoes, description: 'Heeled ankle boots'),
      ],
    };
  }
}
