import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../../wardrobe/domain/entities/clothing_item.dart';

class CategoryCarousel extends StatelessWidget {
  final String categoryName;
  final List<ClothingItem> items;
  final ClothingItem? selectedItem;
  final Function(ClothingItem) onItemTap;

  const CategoryCarousel({
    super.key,
    required this.categoryName,
    required this.items,
    this.selectedItem,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            categoryName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedItem?.id == item.id;

              return GestureDetector(
                onTap: () => onItemTap(item),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildItemImage(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        errorWidget: (context, url, error) => _buildCategoryIcon(item.category),
      );
    } else {
      return _buildCategoryIcon(item.category);
    }
  }

  Widget _buildCategoryIcon(ClothingCategory category) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
