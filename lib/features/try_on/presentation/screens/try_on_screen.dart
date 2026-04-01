import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../../../services/background_removal_service.dart';
import '../../../../services/tips_service.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../providers/try_on_provider.dart';
import '../../domain/entities/try_on_state.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  final Map<String, _OverlayTransform> _transforms = {};
  String? _activeItemId;
  Size _modelAreaSize = Size.zero;
  final _repaintKey = GlobalKey();

  /// Items currently being background-processed (show spinner).
  final _bgProcessing = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (await TipsService.shouldShow('tryon_controls')) {
        await TipsService.markShown('tryon_controls');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tap a garment to select it · Drag to reposition · Use +/− buttons to resize'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  /// Captures the model+overlays and opens the system share sheet.
  Future<void> _saveOutfitImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // Web: share as XFile from memory
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: 'outfit.png', mimeType: 'image/png')],
            text: 'My Smart Closet outfit ✨',
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/outfit_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'My Smart Closet outfit ✨',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Downloads [item]'s image and strips the background, then stores the
  /// result via the provider so the overlay re-renders with transparency.
  Future<void> _triggerBgRemoval(ClothingItem item) async {
    if (_bgProcessing.contains(item.id)) return;
    setState(() => _bgProcessing.add(item.id));

    try {
      Uint8List? imageBytes;
      if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
        final response = await Dio().get<List<int>>(
          item.storageImageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        imageBytes = Uint8List.fromList(response.data!);
      } else if (!kIsWeb && item.localImagePath != null && item.localImagePath!.isNotEmpty) {
        imageBytes = await File(item.localImagePath!).readAsBytes();
      }

      if (imageBytes != null && mounted) {
        final result = await BackgroundRemovalService().removeBackgroundFromBytes(imageBytes);
        if (mounted) {
          ref.read(tryOnProvider.notifier).setCroppedImage(item.id, result);
        }
      }
    } catch (_) {
      // Silently ignore — original image stays visible
    } finally {
      if (mounted) setState(() => _bgProcessing.remove(item.id));
    }
  }

  /// Auto-position and scale based on category and model area size
  _OverlayTransform _createTransformForCategory(ClothingCategory category) {
    final w = _modelAreaSize.width;
    final h = _modelAreaSize.height;

    // Default fallback if area not measured yet
    if (w == 0 || h == 0) return _OverlayTransform();

    // Garment base size relative to model area width (~45% of width)
    final baseWidth = w * 0.45;

    switch (category) {
      case ClothingCategory.tops:
        return _OverlayTransform(
          offset: Offset(w * 0.27, h * 0.15), // Upper torso
          scale: baseWidth / 160, // 160 is base garment width
        );
      case ClothingCategory.outerwear:
        return _OverlayTransform(
          offset: Offset(w * 0.22, h * 0.12), // Slightly wider, higher
          scale: (baseWidth * 1.15) / 160,
        );
      case ClothingCategory.bottoms:
        return _OverlayTransform(
          offset: Offset(w * 0.27, h * 0.45), // Lower torso
          scale: baseWidth / 160,
        );
      case ClothingCategory.dresses:
        return _OverlayTransform(
          offset: Offset(w * 0.25, h * 0.15), // Full torso
          scale: (baseWidth * 1.1) / 160,
        );
      case ClothingCategory.shoes:
        return _OverlayTransform(
          offset: Offset(w * 0.30, h * 0.80), // Feet area
          scale: (baseWidth * 0.6) / 160,
        );
      case ClothingCategory.accessories:
        return _OverlayTransform(
          offset: Offset(w * 0.35, h * 0.05), // Head/neck area
          scale: (baseWidth * 0.5) / 160,
        );
      case ClothingCategory.skirts:
        return _OverlayTransform(
          offset: Offset(w * 0.27, h * 0.45), // Lower torso (same as bottoms)
          scale: baseWidth / 160,
        );
      case ClothingCategory.suits:
        return _OverlayTransform(
          offset: Offset(w * 0.22, h * 0.12), // Full upper body (same as outerwear)
          scale: (baseWidth * 1.1) / 160,
        );
      case ClothingCategory.sportswear:
        return _OverlayTransform(
          offset: Offset(w * 0.27, h * 0.15), // Upper torso (same as tops)
          scale: baseWidth / 160,
        );
      case ClothingCategory.swimwear:
        return _OverlayTransform(
          offset: Offset(w * 0.25, h * 0.15), // Full torso (same as dresses)
          scale: (baseWidth * 1.1) / 160,
        );
      case ClothingCategory.bags:
        return _OverlayTransform(
          offset: Offset(w * 0.60, h * 0.45), // Side/hand area
          scale: (baseWidth * 0.5) / 160,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tryOnState = ref.watch(tryOnProvider);
    final wardrobeItems = ref.watch(wardrobeProvider);

    final itemsByCategory = <ClothingCategory, List<ClothingItem>>{};
    for (final item in wardrobeItems) {
      if (item.effectiveImagePath != null) {
        itemsByCategory.putIfAbsent(item.category, () => []).add(item);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Try-On'),
        backgroundColor: AppColors.surface,
        actions: [
          if (tryOnState.hasModel && tryOnState.overlayItems.isNotEmpty)
            IconButton(
              onPressed: _saveOutfitImage,
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share outfit',
            ),
          if (tryOnState.overlayItems.isNotEmpty)
            IconButton(
              onPressed: () {
                ref.read(tryOnProvider.notifier).clearOverlays();
                _transforms.clear();
              },
              icon: const Icon(Icons.layers_clear),
              tooltip: 'Clear all',
            ),
          if (tryOnState.hasModel)
            IconButton(
              onPressed: () {
                ref.read(tryOnProvider.notifier).reset();
                _transforms.clear();
                _activeItemId = null;
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Start over',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top: Model photo with overlays
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: tryOnState.hasModel
                    ? _buildModelWithOverlays(tryOnState)
                    : _buildPhotoSelector(),
              ),
            ),

            // Hint text
            if (tryOnState.hasModel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        tryOnState.overlayItems.isEmpty
                            ? 'Select a garment below'
                            : 'Drag to move, use +/- to resize',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

            // Bottom: Wardrobe items
            Expanded(
              flex: 4,
              child: wardrobeItems.isEmpty
                  ? Center(
                      child: Text(
                        'Add items to your wardrobe first',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        for (final category in ClothingCategory.values)
                          if (itemsByCategory.containsKey(category))
                            _buildCategoryRow(
                              context,
                              category,
                              itemsByCategory[category]!,
                              tryOnState,
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelWithOverlays(TryOnState tryOnState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _modelAreaSize = Size(constraints.maxWidth, constraints.maxHeight);

        return RepaintBoundary(
          key: _repaintKey,
          child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Model photo
                _buildModelImage(tryOnState),

                // Garment overlays
                for (final item in tryOnState.overlayItems)
                  _buildDraggableGarment(item, tryOnState.croppedImages),

                // Change photo button
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _miniButton(
                    icon: Icons.camera_alt,
                    label: 'Change Photo',
                    onTap: () => _showPhotoSourceDialog(),
                  ),
                ),

                // Controls for active garment
                if (_activeItemId != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Row 1: scale controls
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _iconBtn(Icons.remove, () {
                                final t = _transforms[_activeItemId];
                                if (t != null) {
                                  setState(() => t.scale = (t.scale - 0.05).clamp(0.2, 3.0));
                                }
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '${((_transforms[_activeItemId]?.scale ?? 1.0) * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                              _iconBtn(Icons.add, () {
                                final t = _transforms[_activeItemId];
                                if (t != null) {
                                  setState(() => t.scale = (t.scale + 0.05).clamp(0.2, 3.0));
                                }
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Row 2: crop + delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _miniButton(
                              icon: Icons.crop_rotate,
                              label: 'Crop',
                              onTap: () => _cropGarment(tryOnState),
                            ),
                            const SizedBox(width: 6),
                            _miniButton(
                              icon: Icons.delete_outline,
                              label: 'Remove',
                              color: AppColors.error,
                              onTap: () {
                                final item = tryOnState.overlayItems
                                    .where((i) => i.id == _activeItemId)
                                    .firstOrNull;
                                if (item != null) {
                                  ref.read(tryOnProvider.notifier).removeGarment(item);
                                  _transforms.remove(item.id);
                                  setState(() => _activeItemId = null);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),  // Container
        );  // RepaintBoundary
      },
    );
  }

  Widget _buildDraggableGarment(ClothingItem item, Map<String, Uint8List> croppedImages) {
    final transform = _transforms.putIfAbsent(
      item.id,
      () => _createTransformForCategory(item.category),
    );
    final isActive = _activeItemId == item.id;
    final w = 160 * transform.scale;
    final h = 200 * transform.scale;

    // Auto-remove background the first time this garment appears in the overlay
    if (!croppedImages.containsKey(item.id) && !_bgProcessing.contains(item.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerBgRemoval(item));
    }

    return Positioned(
      left: transform.offset.dx,
      top: transform.offset.dy,
      child: GestureDetector(
        onTap: () => setState(() {
          _activeItemId = _activeItemId == item.id ? null : item.id;
        }),
        onScaleStart: (_) => setState(() => _activeItemId = item.id),
        onScaleUpdate: (details) {
          setState(() {
            if (details.pointerCount >= 2) {
              transform.scale = (transform.scale * details.scale).clamp(0.2, 3.0);
              transform.rotation += details.rotation;
            }
            transform.offset += details.focalPointDelta;
          });
        },
        child: Transform.rotate(
          angle: transform.rotation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Drop shadow + garment image
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(2, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildGarmentOverlay(item, croppedImages[item.id]),
                ),
              ),

              // Background-removal loading indicator
              if (_bgProcessing.contains(item.id))
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              // Corner handles — only when active
              if (isActive) ...[
                Positioned(top: -4,  left: -4,  child: _cornerHandle()),
                Positioned(top: -4,  right: -4, child: _cornerHandle()),
                Positioned(bottom: -4, left: -4,  child: _cornerHandle()),
                Positioned(bottom: -4, right: -4, child: _cornerHandle()),
                // Rotation handle at top-center
                Positioned(
                  top: -22,
                  left: w / 2 - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rotate_left, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerHandle() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.accessibility_new, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Virtual Try-On',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'See how outfits look on you before wearing them',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            // Step guide
            _buildStep('1', Icons.person, 'Upload a full-body photo of yourself'),
            const SizedBox(height: 10),
            _buildStep('2', Icons.checkroom, 'Select garments from your wardrobe below'),
            const SizedBox(height: 10),
            _buildStep('3', Icons.open_with, 'Drag & resize garments to position them'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(tryOnProvider.notifier)
                      .pickModelPhoto(source: ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(tryOnProvider.notifier)
                        .pickModelPhoto(source: ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    ClothingCategory category,
    List<ClothingItem> items,
    TryOnState tryOnState,
  ) {
    final overlayIds = tryOnState.overlayItems.map((i) => i.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '${category.icon} ${category.displayName}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = overlayIds.contains(item.id);

              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    ref.read(tryOnProvider.notifier).removeGarment(item);
                    _transforms.remove(item.id);
                    if (_activeItemId == item.id) {
                      setState(() => _activeItemId = null);
                    }
                  } else {
                    ref.read(tryOnProvider.notifier).addGarment(item);
                  }
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildGarmentImage(item),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper widgets ---

  Widget _buildModelImage(TryOnState tryOnState) {
    // Web: use bytes stored in state (path is not a valid URL on web)
    if (kIsWeb && tryOnState.modelImageBytes != null) {
      return Image.memory(
        tryOnState.modelImageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
    // Mobile: use file path (or Firebase Storage URL)
    final path = tryOnState.modelImagePath ?? '';
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, e, s) =>
            const Center(child: Icon(Icons.broken_image, size: 48)),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, e, s) =>
          const Center(child: Icon(Icons.broken_image, size: 48)),
    );
  }

  /// Overlay garment on model — always contain so transparent-bg garments
  /// are shown in full without clipping.
  Widget _buildGarmentOverlay(ClothingItem item, Uint8List? croppedBytes) {
    if (croppedBytes != null) {
      return Image.memory(
        croppedBytes,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.storageImageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, p) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, e, s) => _garmentIconFallback(item),
      );
    }
    if (!kIsWeb && item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return Image.file(
        File(item.localImagePath!),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, e, s) => _garmentIconFallback(item),
      );
    }
    return _garmentIconFallback(item);
  }

  /// Thumbnail in carousel - uses cover to fill the card
  Widget _buildGarmentImage(ClothingItem item) {
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.storageImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, p) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, e, s) => _garmentIconFallback(item),
      );
    }
    if (!kIsWeb && item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return Image.file(
        File(item.localImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, e, s) => _garmentIconFallback(item),
      );
    }
    return _garmentIconFallback(item);
  }

  Widget _garmentIconFallback(ClothingItem item) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Text(item.category.icon, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.white),
      ),
    );
  }

  Widget _miniButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.black).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropGarment(TryOnState tryOnState) async {
    if (_activeItemId == null || !mounted) return;
    final item = tryOnState.overlayItems
        .where((i) => i.id == _activeItemId)
        .firstOrNull;
    if (item == null) return;

    // Resolve image bytes from cropped cache, storage URL, or local file
    Uint8List? imageBytes;
    final existing = tryOnState.croppedImages[item.id];
    if (existing != null) {
      imageBytes = existing;
    } else if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      try {
        final response = await Dio().get<List<int>>(
          item.storageImageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        imageBytes = Uint8List.fromList(response.data!);
      } catch (_) {}
    } else if (!kIsWeb && item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      imageBytes = await File(item.localImagePath!).readAsBytes();
    }

    if (imageBytes == null || !mounted) return;

    String sourcePath;

    if (kIsWeb) {
      // Web: convert to base64 data URL to avoid CORS canvas taint in cropper.js
      final base64 = base64Encode(imageBytes);
      sourcePath = 'data:image/jpeg;base64,$base64';
    } else {
      // Mobile: write bytes to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/crop_${item.id}.png');
      await tempFile.writeAsBytes(imageBytes);
      sourcePath = tempFile.path;
    }

    if (!mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Garment',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Garment'),
        WebUiSettings(context: context),
      ],
    );

    if (cropped != null && mounted) {
      final bytes = await cropped.readAsBytes();
      ref.read(tryOnProvider.notifier).setCroppedImage(item.id, bytes);
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(tryOnProvider.notifier)
                    .pickModelPhoto(source: ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(tryOnProvider.notifier)
                      .pickModelPhoto(source: ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayTransform {
  Offset offset;
  double scale;
  double rotation = 0.0; // radians — mutated by pinch-rotate gesture

  _OverlayTransform({
    this.offset = const Offset(80, 60),
    this.scale = 1.0,
  });
}
