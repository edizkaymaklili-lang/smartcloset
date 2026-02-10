import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../domain/entities/placed_clothing_item.dart';
import '../../domain/entities/style_board_state.dart';

final styleBoardProvider = NotifierProvider<StyleBoardNotifier, StyleBoardState>(() {
  return StyleBoardNotifier();
});

class StyleBoardNotifier extends Notifier<StyleBoardState> {
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  @override
  StyleBoardState build() {
    return const StyleBoardState();
  }

  /// Pick model photo from gallery
  Future<void> pickModelPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        state = state.copyWith(
          modelImagePath: pickedFile.path,
          status: StyleBoardStatus.modelSelected,
          placedItems: [], // Clear previous items
          clearErrorMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: StyleBoardStatus.error,
        errorMessage: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Add clothing item to the canvas
  void addClothingItem(ClothingItem item, {double? x, double? y}) {
    final placedItem = PlacedClothingItem(
      id: _uuid.v4(),
      clothingItem: item,
      x: x ?? 0.5,
      y: y ?? 0.5,
      scale: 0.3, // Start with smaller size
    );

    state = state.copyWith(
      placedItems: [...state.placedItems, placedItem],
      selectedItemId: placedItem.id,
      status: StyleBoardStatus.editing,
    );
  }

  /// Update position of a placed item
  void updateItemPosition(String id, double x, double y) {
    final updatedItems = state.placedItems.map((item) {
      if (item.id == id) {
        return item.copyWith(x: x.clamp(0.0, 1.0), y: y.clamp(0.0, 1.0));
      }
      return item;
    }).toList();

    state = state.copyWith(placedItems: updatedItems);
  }

  /// Update scale of a placed item
  void updateItemScale(String id, double scale) {
    final updatedItems = state.placedItems.map((item) {
      if (item.id == id) {
        return item.copyWith(scale: scale.clamp(0.1, 3.0));
      }
      return item;
    }).toList();

    state = state.copyWith(placedItems: updatedItems);
  }

  /// Update rotation of a placed item
  void updateItemRotation(String id, double rotation) {
    final updatedItems = state.placedItems.map((item) {
      if (item.id == id) {
        return item.copyWith(rotation: rotation);
      }
      return item;
    }).toList();

    state = state.copyWith(placedItems: updatedItems);
  }

  /// Select an item
  void selectItem(String id) {
    state = state.copyWith(selectedItemId: id);
  }

  /// Deselect item
  void deselectItem() {
    state = state.copyWith(clearSelectedItemId: true);
  }

  /// Remove a placed item
  void removeItem(String id) {
    final updatedItems = state.placedItems.where((item) => item.id != id).toList();
    state = state.copyWith(
      placedItems: updatedItems,
      clearSelectedItemId: true,
    );
  }

  /// Bring item to front (z-index)
  void bringToFront(String id) {
    final item = state.placedItems.firstWhere((i) => i.id == id);
    final updatedItems = state.placedItems.where((i) => i.id != id).toList()..add(item);
    state = state.copyWith(placedItems: updatedItems);
  }

  /// Send item to back (z-index)
  void sendToBack(String id) {
    final item = state.placedItems.firstWhere((i) => i.id == id);
    final updatedItems = [item, ...state.placedItems.where((i) => i.id != id)];
    state = state.copyWith(placedItems: updatedItems);
  }

  /// Clear all items
  void clearAllItems() {
    state = state.copyWith(
      placedItems: [],
      clearSelectedItemId: true,
    );
  }

  /// Reset the board
  void reset() {
    state = const StyleBoardState();
  }
}
