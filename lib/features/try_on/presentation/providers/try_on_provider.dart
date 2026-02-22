import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../domain/entities/try_on_state.dart';

final tryOnProvider = NotifierProvider<TryOnNotifier, TryOnState>(() {
  return TryOnNotifier();
});

class TryOnNotifier extends Notifier<TryOnState> {
  final _imagePicker = ImagePicker();

  @override
  TryOnState build() {
    return const TryOnState();
  }

  /// Pick model photo from gallery or camera
  Future<void> pickModelPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        state = state.copyWith(
          modelImagePath: pickedFile.path,
          overlayItems: [],
          clearErrorMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Add a garment overlay on the model
  void addGarment(ClothingItem item) {
    if (!state.hasModel) {
      state = state.copyWith(
        errorMessage: 'Please select your photo first',
      );
      return;
    }

    // Remove existing item of same category (replace top with top, etc.)
    final updated = state.overlayItems
        .where((i) => i.category != item.category)
        .toList()
      ..add(item);

    state = state.copyWith(
      selectedItem: item,
      overlayItems: updated,
      clearErrorMessage: true,
    );
  }

  /// Remove a garment from overlay
  void removeGarment(ClothingItem item) {
    final updated = state.overlayItems.where((i) => i.id != item.id).toList();
    state = state.copyWith(
      overlayItems: updated,
      clearSelectedItem: true,
    );
  }

  /// Clear all overlays
  void clearOverlays() {
    state = state.copyWith(
      overlayItems: [],
      clearSelectedItem: true,
    );
  }

  /// Reset everything
  void reset() {
    state = const TryOnState();
  }
}
