import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../providers/try_on_provider.dart';
import '../widgets/category_carousel.dart';
import '../widgets/try_on_result_view.dart';
import '../widgets/manual_alignment_widget.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  bool _showManualAlignment = false;
  ClothingItem? _selectedGarment;

  @override
  Widget build(BuildContext context) {
    final tryOnState = ref.watch(tryOnProvider);
    final wardrobeItems = ref.watch(wardrobeProvider);

    // Group items by category
    final itemsByCategory = <ClothingCategory, List<ClothingItem>>{};
    for (final item in wardrobeItems) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    // Show manual alignment if active
    if (_showManualAlignment &&
        tryOnState.modelImagePath != null &&
        _selectedGarment?.localImagePath != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manual Alignment'),
          backgroundColor: AppColors.surface,
        ),
        body: ManualAlignmentWidget(
          bodyPhoto: File(tryOnState.modelImagePath!),
          garmentPhoto: File(_selectedGarment!.localImagePath!),
          onSave: () {
            ref.read(tryOnProvider.notifier).saveManualAlignment();
            setState(() {
              _showManualAlignment = false;
              _selectedGarment = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Try-on complete! Take screenshot to save.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onCancel: () {
            setState(() {
              _showManualAlignment = false;
              _selectedGarment = null;
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Try-On'),
        backgroundColor: AppColors.surface,
        actions: [
          if (tryOnState.modelImagePath != null)
            IconButton(
              onPressed: () {
                ref.read(tryOnProvider.notifier).reset();
                setState(() {
                  _showManualAlignment = false;
                  _selectedGarment = null;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top half: Result view
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TryOnResultView(
                  state: tryOnState,
                  onPickPhoto: () {
                    ref.read(tryOnProvider.notifier).pickModelPhoto();
                  },
                  onClearResult: () {
                    ref.read(tryOnProvider.notifier).clearResult();
                  },
                ),
              ),
            ),

            const Divider(height: 1),

            // Bottom half: Category carousels
            Expanded(
              flex: 5,
              child: wardrobeItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checkroom_outlined,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in wardrobe',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items to your wardrobe to try them on',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        // Show only supported categories
                        if (itemsByCategory.containsKey(ClothingCategory.tops))
                          CategoryCarousel(
                            categoryName: 'Tops',
                            items: itemsByCategory[ClothingCategory.tops]!,
                            selectedItem: tryOnState.selectedItem,
                            onItemTap: (item) {
                              // Use manual alignment
                              setState(() {
                                _selectedGarment = item;
                                _showManualAlignment = true;
                              });
                              ref.read(tryOnProvider.notifier).startManualAlignment(item);
                            },
                          ),
                        if (itemsByCategory.containsKey(ClothingCategory.bottoms))
                          CategoryCarousel(
                            categoryName: 'Bottoms',
                            items: itemsByCategory[ClothingCategory.bottoms]!,
                            selectedItem: tryOnState.selectedItem,
                            onItemTap: (item) {
                              setState(() {
                                _selectedGarment = item;
                                _showManualAlignment = true;
                              });
                              ref.read(tryOnProvider.notifier).startManualAlignment(item);
                            },
                          ),
                        if (itemsByCategory.containsKey(ClothingCategory.dresses))
                          CategoryCarousel(
                            categoryName: 'Dresses',
                            items: itemsByCategory[ClothingCategory.dresses]!,
                            selectedItem: tryOnState.selectedItem,
                            onItemTap: (item) {
                              setState(() {
                                _selectedGarment = item;
                                _showManualAlignment = true;
                              });
                              ref.read(tryOnProvider.notifier).startManualAlignment(item);
                            },
                          ),
                        if (itemsByCategory.containsKey(ClothingCategory.outerwear))
                          CategoryCarousel(
                            categoryName: 'Outerwear',
                            items: itemsByCategory[ClothingCategory.outerwear]!,
                            selectedItem: tryOnState.selectedItem,
                            onItemTap: (item) {
                              setState(() {
                                _selectedGarment = item;
                                _showManualAlignment = true;
                              });
                              ref.read(tryOnProvider.notifier).startManualAlignment(item);
                            },
                          ),

                        // Info about unsupported categories
                        if (itemsByCategory.containsKey(ClothingCategory.shoes) ||
                            itemsByCategory.containsKey(ClothingCategory.accessories))
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Shoes and accessories are not yet supported for virtual try-on',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
