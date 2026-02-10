import '../../../wardrobe/domain/entities/clothing_item.dart';

class PlacedClothingItem {
  final String id;
  final ClothingItem clothingItem;
  final double x; // Position X (0-1, relative to canvas)
  final double y; // Position Y (0-1, relative to canvas)
  final double scale; // Scale factor (0.5 - 2.0)
  final double rotation; // Rotation in radians (0 - 2π)

  const PlacedClothingItem({
    required this.id,
    required this.clothingItem,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  PlacedClothingItem copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    return PlacedClothingItem(
      id: id,
      clothingItem: clothingItem,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}
