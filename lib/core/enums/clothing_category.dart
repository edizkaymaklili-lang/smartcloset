enum ClothingCategory {
  tops,
  bottoms,
  outerwear,
  shoes,
  accessories,
  dresses;

  String get displayName {
    return switch (this) {
      ClothingCategory.tops => 'Tops',
      ClothingCategory.bottoms => 'Bottoms',
      ClothingCategory.outerwear => 'Outerwear',
      ClothingCategory.shoes => 'Shoes',
      ClothingCategory.accessories => 'Accessories',
      ClothingCategory.dresses => 'Dresses',
    };
  }

  String get icon {
    return switch (this) {
      ClothingCategory.tops => '👚',
      ClothingCategory.bottoms => '👖',
      ClothingCategory.outerwear => '🧥',
      ClothingCategory.shoes => '👠',
      ClothingCategory.accessories => '💍',
      ClothingCategory.dresses => '👗',
    };
  }
}
