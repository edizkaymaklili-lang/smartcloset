import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';

class ClothingItemSelector extends StatelessWidget {
  final List<ClothingItem> items;
  final Function(ClothingItem) onItemTap;

  const ClothingItemSelector({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checkroom_outlined,
                size: 32,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 4),
              Text(
                'No items',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onItemTap(item),
          child: Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildItemImage(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(ClothingItem item) {
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.storageImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildIconFallback(item),
      );
    } else if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return kIsWeb
          ? Image.network(
              item.localImagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildIconFallback(item),
            )
          : Image.file(
              File(item.localImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildIconFallback(item),
            );
    } else {
      return _buildIconFallback(item);
    }
  }

  Widget _buildIconFallback(ClothingItem item) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          item.category.icon,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
