import '../../../wardrobe/domain/entities/clothing_item.dart';

enum TryOnStatus {
  idle,
  uploading,
  processing,
  done,
  error,
}

class TryOnState {
  final String? modelImagePath;
  final ClothingItem? selectedItem;
  final TryOnStatus status;
  final String? resultImageUrl;
  final String? errorMessage;

  const TryOnState({
    this.modelImagePath,
    this.selectedItem,
    this.status = TryOnStatus.idle,
    this.resultImageUrl,
    this.errorMessage,
  });

  TryOnState copyWith({
    String? modelImagePath,
    ClothingItem? selectedItem,
    TryOnStatus? status,
    String? resultImageUrl,
    String? errorMessage,
    bool clearSelectedItem = false,
    bool clearResultImageUrl = false,
    bool clearErrorMessage = false,
  }) {
    return TryOnState(
      modelImagePath: modelImagePath ?? this.modelImagePath,
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
      status: status ?? this.status,
      resultImageUrl: clearResultImageUrl ? null : (resultImageUrl ?? this.resultImageUrl),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get canTryOn => modelImagePath != null && status == TryOnStatus.idle;
}
