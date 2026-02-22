import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
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

        return Container(
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
                _buildImage(tryOnState.modelImagePath!),

                // Garment overlays
                for (final item in tryOnState.overlayItems)
                  _buildDraggableGarment(item),

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
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                              setState(() => t.scale = (t.scale - 0.15).clamp(0.2, 3.0));
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
                              setState(() => t.scale = (t.scale + 0.15).clamp(0.2, 3.0));
                            }
                          }),
                          const SizedBox(width: 8),
                          _iconBtn(Icons.delete_outline, () {
                            final item = tryOnState.overlayItems
                                .where((i) => i.id == _activeItemId)
                                .firstOrNull;
                            if (item != null) {
                              ref.read(tryOnProvider.notifier).removeGarment(item);
                              _transforms.remove(item.id);
                              setState(() => _activeItemId = null);
                            }
                          }, color: AppColors.error),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableGarment(ClothingItem item) {
    final transform = _transforms.putIfAbsent(
      item.id,
      () => _createTransformForCategory(item.category),
    );
    final isActive = _activeItemId == item.id;

    return Positioned(
      left: transform.offset.dx,
      top: transform.offset.dy,
      child: GestureDetector(
        onTap: () => setState(() {
          _activeItemId = _activeItemId == item.id ? null : item.id;
        }),
        onPanUpdate: (details) {
          setState(() {
            _activeItemId = item.id;
            transform.offset += details.delta;
          });
        },
        onScaleStart: (_) {
          setState(() => _activeItemId = item.id);
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            setState(() {
              transform.scale = (transform.scale * details.scale).clamp(0.2, 3.0);
            });
          }
        },
        child: Container(
          decoration: isActive
              ? BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Opacity(
            opacity: 0.88,
            child: SizedBox(
              width: 160 * transform.scale,
              height: 200 * transform.scale,
              child: _buildGarmentOverlay(item),
            ),
          ),
        ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 72, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Upload Your Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Full-body photo works best',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(tryOnProvider.notifier)
                    .pickModelPhoto(source: ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(tryOnProvider.notifier)
                      .pickModelPhoto(source: ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
            ],
          ),
        ],
      ),
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

  Widget _buildImage(String path) {
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, e, s) => const Center(
          child: Icon(Icons.broken_image, size: 48),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, e, s) => const Center(
        child: Icon(Icons.broken_image, size: 48),
      ),
    );
  }

  /// Overlay garment on model - uses contain so full garment is visible
  Widget _buildGarmentOverlay(ClothingItem item) {
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

  _OverlayTransform({
    this.offset = const Offset(80, 60),
    this.scale = 1.0,
  });
}
