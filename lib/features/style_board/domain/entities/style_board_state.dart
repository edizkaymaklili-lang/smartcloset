import 'placed_clothing_item.dart';

enum StyleBoardStatus {
  initial,
  modelSelected,
  editing,
  saving,
  saved,
  error,
}

class StyleBoardState {
  final String? modelImagePath;
  final List<PlacedClothingItem> placedItems;
  final String? selectedItemId;
  final StyleBoardStatus status;
  final String? errorMessage;

  const StyleBoardState({
    this.modelImagePath,
    this.placedItems = const [],
    this.selectedItemId,
    this.status = StyleBoardStatus.initial,
    this.errorMessage,
  });

  StyleBoardState copyWith({
    String? modelImagePath,
    List<PlacedClothingItem>? placedItems,
    String? selectedItemId,
    StyleBoardStatus? status,
    String? errorMessage,
    bool clearSelectedItemId = false,
    bool clearModelImagePath = false,
    bool clearErrorMessage = false,
  }) {
    return StyleBoardState(
      modelImagePath: clearModelImagePath ? null : (modelImagePath ?? this.modelImagePath),
      placedItems: placedItems ?? this.placedItems,
      selectedItemId: clearSelectedItemId ? null : (selectedItemId ?? this.selectedItemId),
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasModel => modelImagePath != null;
  PlacedClothingItem? get selectedItem {
    if (selectedItemId == null) return null;
    try {
      return placedItems.firstWhere((item) => item.id == selectedItemId);
    } catch (_) {
      return null;
    }
  }
}
