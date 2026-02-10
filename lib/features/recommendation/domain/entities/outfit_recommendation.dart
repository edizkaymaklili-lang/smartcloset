import '../../../../core/enums/clothing_category.dart';
import '../../../../core/enums/outfit_occasion.dart';

class OutfitRecommendation {
  final String id;
  final DateTime date;
  final Map<OutfitOccasion, OccasionOutfit> occasions;
  final List<String> smartTips;

  const OutfitRecommendation({
    required this.id,
    required this.date,
    required this.occasions,
    this.smartTips = const [],
  });
}

class OccasionOutfit {
  final List<OutfitItem> items;
  final MakeupRecommendation makeup;
  final List<String> accessories;
  final String? smartTip;

  const OccasionOutfit({
    required this.items,
    required this.makeup,
    this.accessories = const [],
    this.smartTip,
  });
}

class OutfitItem {
  final ClothingCategory category;
  final String description;
  final String? imageUrl;
  final String? wardrobeItemId; // set when matched to user's actual wardrobe

  const OutfitItem({
    required this.category,
    required this.description,
    this.imageUrl,
    this.wardrobeItemId,
  });

  bool get isFromWardrobe => wardrobeItemId != null;
}

class MakeupRecommendation {
  final String foundation;
  final String lips;
  final String eyes;
  final String tip;

  const MakeupRecommendation({
    required this.foundation,
    required this.lips,
    required this.eyes,
    required this.tip,
  });
}
