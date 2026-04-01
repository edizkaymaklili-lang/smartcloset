import 'dart:typed_data';
import '../../../wardrobe/domain/entities/clothing_item.dart';

class TryOnState {
  final String? modelImagePath;
  final Uint8List? modelImageBytes; // Web: bytes for Image.memory (path is invalid on web)
  final ClothingItem? selectedItem;
  final List<ClothingItem> overlayItems; // Multiple garments on model
  final Map<String, Uint8List> croppedImages; // itemId → user-cropped bytes
  final String? errorMessage;

  const TryOnState({
    this.modelImagePath,
    this.modelImageBytes,
    this.selectedItem,
    this.overlayItems = const [],
    this.croppedImages = const {},
    this.errorMessage,
  });

  TryOnState copyWith({
    String? modelImagePath,
    Uint8List? modelImageBytes,
    ClothingItem? selectedItem,
    List<ClothingItem>? overlayItems,
    Map<String, Uint8List>? croppedImages,
    String? errorMessage,
    bool clearSelectedItem = false,
    bool clearErrorMessage = false,
    bool clearModelImage = false,
  }) {
    return TryOnState(
      modelImagePath: clearModelImage ? null : (modelImagePath ?? this.modelImagePath),
      modelImageBytes: clearModelImage ? null : (modelImageBytes ?? this.modelImageBytes),
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
      overlayItems: overlayItems ?? this.overlayItems,
      croppedImages: croppedImages ?? this.croppedImages,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasModel => modelImagePath != null || modelImageBytes != null;
}
