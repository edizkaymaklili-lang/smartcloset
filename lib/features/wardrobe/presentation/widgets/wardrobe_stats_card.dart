import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/clothing_item.dart';

class WardrobeStatsCard extends StatelessWidget {
  final List<ClothingItem> items;

  const WardrobeStatsCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final favorites = items.where((i) => i.isFavorite).length;
    final rarelyWorn = items.where((i) {
      if (i.lastWorn == null) return true;
      return DateTime.now().difference(i.lastWorn!).inDays > 30;
    }).length;
    final newItems = items.where((i) => i.lastWorn == null).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'My Closet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.checkroom,
                    label: 'Total',
                    value: items.length.toString(),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    value: favorites.toString(),
                    color: AppColors.error,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.fiber_new,
                    label: 'New',
                    value: newItems.toString(),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (rarelyWorn > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$rarelyWorn items haven\'t been worn in 30+ days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning.withValues(alpha: 0.9),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
