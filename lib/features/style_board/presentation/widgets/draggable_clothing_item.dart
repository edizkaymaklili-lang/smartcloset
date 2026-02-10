import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/placed_clothing_item.dart';

class DraggableClothingItemWidget extends StatelessWidget {
  final PlacedClothingItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDelete;

  const DraggableClothingItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onDragUpdate,
      child: Transform.rotate(
        angle: item.rotation,
        child: Transform.scale(
          scale: item.scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Clothing image
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 3)
                      : Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildClothingImage(),
                ),
              ),

              // Delete button (only when selected)
              if (isSelected)
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClothingImage() {
    final clothingItem = item.clothingItem;

    if (clothingItem.storageImageUrl != null &&
        clothingItem.storageImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: clothingItem.storageImageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildIconFallback(),
      );
    } else if (clothingItem.localImagePath != null &&
        clothingItem.localImagePath!.isNotEmpty) {
      return kIsWeb
          ? Image.network(
              clothingItem.localImagePath!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildIconFallback(),
            )
          : Image.file(
              File(clothingItem.localImagePath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildIconFallback(),
            );
    } else {
      return _buildIconFallback();
    }
  }

  Widget _buildIconFallback() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          item.clothingItem.category.icon,
          style: const TextStyle(fontSize: 60),
        ),
      ),
    );
  }
}
