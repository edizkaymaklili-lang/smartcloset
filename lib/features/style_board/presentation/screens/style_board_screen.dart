import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../providers/style_board_provider.dart';
import '../widgets/clothing_item_selector.dart';
import '../widgets/draggable_clothing_item.dart';

class StyleBoardScreen extends ConsumerWidget {
  const StyleBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleBoardState = ref.watch(styleBoardProvider);
    final wardrobeItems = ref.watch(wardrobeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Board'),
        backgroundColor: AppColors.surface,
        actions: [
          if (styleBoardState.placedItems.isNotEmpty)
            IconButton(
              onPressed: () {
                ref.read(styleBoardProvider.notifier).clearAllItems();
              },
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
            ),
          if (styleBoardState.hasModel)
            IconButton(
              onPressed: () {
                ref.read(styleBoardProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Container(
                color: AppColors.background,
                child: styleBoardState.hasModel
                    ? _buildCanvas(context, ref, styleBoardState)
                    : _buildModelSelector(context, ref),
              ),
            ),
            const Divider(height: 1),
            Container(
              height: 120,
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Tap to add clothing items',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    child: ClothingItemSelector(
                      items: wardrobeItems,
                      onItemTap: (item) {
                        if (styleBoardState.hasModel) {
                          ref.read(styleBoardProvider.notifier).addClothingItem(item);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a model photo first'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: styleBoardState.selectedItem != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'scale_up',
                  onPressed: () {
                    final item = styleBoardState.selectedItem!;
                    ref.read(styleBoardProvider.notifier).updateItemScale(item.id, item.scale + 0.1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'scale_down',
                  onPressed: () {
                    final item = styleBoardState.selectedItem!;
                    ref.read(styleBoardProvider.notifier).updateItemScale(item.id, item.scale - 0.1);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'rotate',
                  onPressed: () {
                    final item = styleBoardState.selectedItem!;
                    ref.read(styleBoardProvider.notifier).updateItemRotation(item.id, item.rotation + 0.1);
                  },
                  child: const Icon(Icons.rotate_right),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildModelSelector(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(styleBoardProvider.notifier).pickModelPhoto();
        },
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Upload Model Photo', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Choose a photo to start styling', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(BuildContext context, WidgetRef ref, styleBoardState) {
    return GestureDetector(
      onTap: () => ref.read(styleBoardProvider.notifier).deselectItem(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              if (styleBoardState.modelImagePath != null)
                Positioned.fill(
                  child: kIsWeb
                      ? Image.network(styleBoardState.modelImagePath!, fit: BoxFit.contain)
                      : Image.file(File(styleBoardState.modelImagePath!), fit: BoxFit.contain),
                ),
              ...styleBoardState.placedItems.map((placedItem) {
                final isSelected = styleBoardState.selectedItemId == placedItem.id;
                return Positioned(
                  left: placedItem.x * constraints.maxWidth - 75,
                  top: placedItem.y * constraints.maxHeight - 75,
                  child: DraggableClothingItemWidget(
                    item: placedItem,
                    isSelected: isSelected,
                    onTap: () => ref.read(styleBoardProvider.notifier).selectItem(placedItem.id),
                    onDragUpdate: (details) {
                      final newX = (placedItem.x * constraints.maxWidth + details.delta.dx) / constraints.maxWidth;
                      final newY = (placedItem.y * constraints.maxHeight + details.delta.dy) / constraints.maxHeight;
                      ref.read(styleBoardProvider.notifier).updateItemPosition(placedItem.id, newX, newY);
                    },
                    onDelete: () => ref.read(styleBoardProvider.notifier).removeItem(placedItem.id),
                  ),
                );
              }).toList(),
              if (styleBoardState.placedItems.isEmpty)
                Positioned(
                  bottom: 16, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Tap clothing items below to add them here', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
