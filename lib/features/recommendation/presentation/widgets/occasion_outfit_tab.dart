import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/outfit_recommendation.dart';

class OccasionOutfitTab extends StatelessWidget {
  final OccasionOutfit outfit;
  final VoidCallback? onRegenerate;

  const OccasionOutfitTab({
    super.key,
    required this.outfit,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          icon: Icons.checkroom_outlined,
          title: 'Outfit',
          color: AppColors.primary,
          trailing: onRegenerate != null
              ? IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 20,
                  color: AppColors.primary,
                  onPressed: onRegenerate,
                  tooltip: 'Regenerate outfit',
                )
              : null,
          child: Column(
            children: outfit.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OutfitItemThumb(item: item),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item.category.displayName,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (item.isFromWardrobe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'From your wardrobe',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.face_retouching_natural,
          title: 'Makeup',
          color: AppColors.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MakeupRow(label: 'Foundation', value: outfit.makeup.foundation),
              _MakeupRow(label: 'Lips', value: outfit.makeup.lips),
              _MakeupRow(label: 'Eyes', value: outfit.makeup.eyes),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        outfit.makeup.tip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.diamond_outlined,
          title: 'Accessories',
          color: AppColors.warning,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: outfit.accessories.map((acc) {
              return Chip(
                label: Text(acc, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.sunny.withValues(alpha: 0.12),
                side: BorderSide(color: AppColors.sunny.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Great choice! Saved to your style history. 👗'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('I Wore This!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _OutfitItemThumb extends StatelessWidget {
  final OutfitItem item;

  const _OutfitItemThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = item.imageUrl;
    if (url != null) {
      if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover,
            errorBuilder: (ctx, e, st) => _fallback());
      }
      // Local file path
      return kIsWeb
          ? Image.network(url, fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => _fallback())
          : Image.file(File(url), fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.5),
      child: Center(
        child: Text(
          item.category.icon,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MakeupRow extends StatelessWidget {
  final String label;
  final String value;

  const _MakeupRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
