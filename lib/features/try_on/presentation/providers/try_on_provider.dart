import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/fashn_service.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../domain/entities/try_on_state.dart';

final tryOnProvider = NotifierProvider<TryOnNotifier, TryOnState>(() {
  return TryOnNotifier();
});

class TryOnNotifier extends Notifier<TryOnState> {
  final _imagePicker = ImagePicker();
  final _fashnService = FashnService();

  @override
  TryOnState build() {
    return const TryOnState();
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
          status: TryOnStatus.idle,
          clearResultImageUrl: true,
          clearErrorMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: TryOnStatus.error,
        errorMessage: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Select clothing item and run try-on
  Future<void> selectItem(ClothingItem item) async {
    // Guard: model photo must be selected first
    if (state.modelImagePath == null) {
      state = state.copyWith(
        status: TryOnStatus.error,
        errorMessage: 'Please select a model photo first',
      );
      return;
    }

    // Check if category is supported
    final fashnCategory = FashnService.mapCategory(item.category.name);
    if (fashnCategory == null) {
      state = state.copyWith(
        status: TryOnStatus.error,
        errorMessage: 'This category is not supported for try-on yet',
      );
      return;
    }

    state = state.copyWith(
      selectedItem: item,
      status: TryOnStatus.uploading,
      clearErrorMessage: true,
      clearResultImageUrl: true,
    );

    try {
      // Read model image bytes
      final modelFile = File(state.modelImagePath!);
      final modelBytes = await modelFile.readAsBytes();

      // Determine garment image (URL or local file)
      String garmentImage;
      if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
        garmentImage = item.storageImageUrl!;
      } else if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
        final garmentFile = File(item.localImagePath!);
        final garmentBytes = await garmentFile.readAsBytes();
        garmentImage = base64Encode(garmentBytes); // Properly encode to base64
      } else {
        throw Exception('No garment image available');
      }

      state = state.copyWith(status: TryOnStatus.processing);

      // Call Fashn.ai service
      final resultUrl = await _fashnService.runTryOn(
        modelImageBytes: modelBytes,
        garmentImage: garmentImage,
        category: fashnCategory,
      );

      state = state.copyWith(
        status: TryOnStatus.done,
        resultImageUrl: resultUrl,
      );
    } catch (e) {
      state = state.copyWith(
        status: TryOnStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset to initial state
  void reset() {
    state = const TryOnState();
  }

  /// Clear result and go back to idle
  void clearResult() {
    state = state.copyWith(
      status: TryOnStatus.idle,
      clearResultImageUrl: true,
      clearSelectedItem: true,
      clearErrorMessage: true,
    );
  }

  /// Start manual alignment mode
  void startManualAlignment(ClothingItem item) {
    if (state.modelImagePath == null) {
      state = state.copyWith(
        status: TryOnStatus.error,
        errorMessage: 'Please select a model photo first',
      );
      return;
    }

    state = state.copyWith(
      selectedItem: item,
      status: TryOnStatus.idle, // Keep idle for manual mode
      clearErrorMessage: true,
    );
  }

  /// Save manual alignment result (placeholder - actual save logic to be added)
  void saveManualAlignment() {
    state = state.copyWith(
      status: TryOnStatus.done,
    );
  }
}
