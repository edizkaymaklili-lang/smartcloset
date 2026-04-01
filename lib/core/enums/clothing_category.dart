enum ClothingCategory {
  tops,
  bottoms,
  skirts,
  dresses,
  outerwear,
  suits,
  sportswear,
  swimwear,
  shoes,
  bags,
  accessories;

  String get displayName {
    return switch (this) {
      ClothingCategory.tops => 'Tops',
      ClothingCategory.bottoms => 'Bottoms',
      ClothingCategory.skirts => 'Skirts',
      ClothingCategory.dresses => 'Dresses',
      ClothingCategory.outerwear => 'Outerwear',
      ClothingCategory.suits => 'Suits & Blazers',
      ClothingCategory.sportswear => 'Sportswear',
      ClothingCategory.swimwear => 'Swimwear',
      ClothingCategory.shoes => 'Shoes',
      ClothingCategory.bags => 'Bags',
      ClothingCategory.accessories => 'Accessories',
    };
  }

  String get icon {
    return switch (this) {
      ClothingCategory.tops => '👚',
      ClothingCategory.bottoms => '👖',
      ClothingCategory.skirts => '🩱',
      ClothingCategory.dresses => '👗',
      ClothingCategory.outerwear => '🧥',
      ClothingCategory.suits => '🤵',
      ClothingCategory.sportswear => '🎽',
      ClothingCategory.swimwear => '👙',
      ClothingCategory.shoes => '👠',
      ClothingCategory.bags => '👜',
      ClothingCategory.accessories => '💍',
    };
  }
}
