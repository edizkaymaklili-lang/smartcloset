import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/clothing_item.dart';
import '../providers/collection_provider.dart';

class ClothingDetailModal extends ConsumerWidget {
  final ClothingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMarkWorn;

  const ClothingDetailModal({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onMarkWorn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          SizedBox(
            height: 300,
            width: double.infinity,
            child: _buildImage(),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: item.isFavorite ? AppColors.error : AppColors.textSecondary,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: item.category.displayName,
                  ),
                  if (item.color.isNotEmpty)
                    _DetailRow(
                      icon: Icons.palette_outlined,
                      label: 'Color',
                      value: item.color,
                    ),
                  if (item.seasons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Seasons',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.seasons.map((season) {
                        return Chip(
                          label: Text(season),
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                  if (item.occasions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Occasions',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.occasions.map((occasion) {
                        return Chip(
                          label: Text(occasion),
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                  if (item.lastWorn != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Last worn',
                      value: _formatLastWorn(item.lastWorn!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onMarkWorn();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Worn Today'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddToCollectionSheet(context, ref),
                    icon: const Icon(Icons.collections_outlined),
                    label: const Text('Add to Collection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.storageImageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _iconFallback(),
      );
    } else if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return kIsWeb
          ? Image.network(
              item.localImagePath!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _iconFallback(),
            )
          : Image.file(
              File(item.localImagePath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _iconFallback(),
            );
    } else {
      return _iconFallback();
    }
  }

  Widget _iconFallback() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          item.category.icon,
          style: const TextStyle(fontSize: 100),
        ),
      ),
    );
  }

  String _formatLastWorn(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  void _showAddToCollectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, child) {
          final collectionsAsync = ref.watch(collectionProvider);

          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Add to Collection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: collectionsAsync.when(
                      data: (collections) => collections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.collections_outlined,
                                size: 60, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'No collections yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a collection first',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: collections.length,
                        itemBuilder: (_, i) {
                          final collection = collections[i];
                          final isInCollection =
                              collection.itemIds.contains(item.id);

                          return ListTile(
                            leading: collection.icon != null
                                ? Text(collection.icon!,
                                    style: const TextStyle(fontSize: 28))
                                : const Icon(Icons.collections_outlined),
                            title: Text(collection.name),
                            subtitle: Text('${collection.itemIds.length} items'),
                            trailing: isInCollection
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.primary)
                                : const Icon(Icons.add_circle_outline,
                                    color: AppColors.textSecondary),
                            onTap: () {
                              if (isInCollection) {
                                ref
                                    .read(collectionProvider.notifier)
                                    .removeItemFromCollection(
                                      collection.id,
                                      item.id,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Removed from "${collection.name}"'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } else {
                                ref
                                    .read(collectionProvider.notifier)
                                    .addItemToCollection(
                                      collection.id,
                                      item.id,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Added to "${collection.name}"'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const Center(child: Text('Error loading collections')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
