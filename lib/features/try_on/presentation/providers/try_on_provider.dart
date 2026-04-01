import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../domain/entities/try_on_state.dart';

const _kModelPhotoPathKey = 'try_on_model_photo_path';

final tryOnProvider = NotifierProvider<TryOnNotifier, TryOnState>(() {
  return TryOnNotifier();
});

class TryOnNotifier extends Notifier<TryOnState> {
  final _imagePicker = ImagePicker();

  @override
  TryOnState build() {
    // Restore saved photo on startup (mobile only)
    _loadSavedPhoto();
    return const TryOnState();
  }

  Future<void> _loadSavedPhoto() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_kModelPhotoPathKey);
    if (savedPath != null && File(savedPath).existsSync()) {
      state = state.copyWith(modelImagePath: savedPath);
    } else if (savedPath != null) {
      // File was deleted externally — clean up stale key
      await prefs.remove(_kModelPhotoPathKey);
    }
  }

  /// Pick model photo from gallery or camera
  Future<void> pickModelPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 82,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Web: store bytes — path is not a valid URL
          final bytes = await pickedFile.readAsBytes();
          state = state.copyWith(
            modelImageBytes: bytes,
            overlayItems: [],
            clearErrorMessage: true,
          );
        } else {
          // Mobile: copy to permanent location so it survives cache clears
          final permanentPath = await _savePermanently(pickedFile.path);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kModelPhotoPathKey, permanentPath);
          state = state.copyWith(
            modelImagePath: permanentPath,
            overlayItems: [],
            clearErrorMessage: true,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  Future<String> _savePermanently(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dest = File('${docsDir.path}/try_on_model_photo.jpg');
    await File(sourcePath).copy(dest.path);
    return dest.path;
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
    final cropped = Map<String, Uint8List>.from(state.croppedImages)..remove(item.id);
    state = state.copyWith(
      overlayItems: updated,
      croppedImages: cropped,
      clearSelectedItem: true,
    );
  }

  /// Clear all overlays
  void clearOverlays() {
    state = state.copyWith(
      overlayItems: [],
      croppedImages: {},
      clearSelectedItem: true,
    );
  }

  /// Store user-cropped bytes for a garment overlay
  void setCroppedImage(String itemId, Uint8List bytes) {
    final updated = Map<String, Uint8List>.from(state.croppedImages)..[itemId] = bytes;
    state = state.copyWith(croppedImages: updated);
  }

  /// Reset everything (clears saved photo on mobile)
  Future<void> reset() async {
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kModelPhotoPathKey);
    }
    state = const TryOnState();
  }
}
