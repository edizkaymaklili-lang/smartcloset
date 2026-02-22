import '../../../wardrobe/domain/entities/clothing_item.dart';

class TryOnState {
  final String? modelImagePath;
  final ClothingItem? selectedItem;
  final List<ClothingItem> overlayItems; // Multiple garments on model
  final String? errorMessage;

  const TryOnState({
    this.modelImagePath,
    this.selectedItem,
    this.overlayItems = const [],
    this.errorMessage,
  });

  TryOnState copyWith({
    String? modelImagePath,
    ClothingItem? selectedItem,
    List<ClothingItem>? overlayItems,
    String? errorMessage,
    bool clearSelectedItem = false,
    bool clearErrorMessage = false,
    bool clearModelImage = false,
  }) {
    return TryOnState(
      modelImagePath: clearModelImage ? null : (modelImagePath ?? this.modelImagePath),
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
      overlayItems: overlayItems ?? this.overlayItems,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasModel => modelImagePath != null;
}
