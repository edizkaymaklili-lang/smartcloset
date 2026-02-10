import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/wardrobe_collection.dart';
import '../../domain/entities/clothing_item.dart';
import '../providers/collection_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/clothing_detail_modal.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionProvider);
    final allItems = ref.watch(wardrobeProvider);

    return collectionsAsync.when(
      data: (collections) {
        final collection = collections.firstWhere(
          (c) => c.id == widget.collectionId,
          orElse: () => throw Exception('Collection not found'),
        );

        final collectionItems = allItems
            .where((item) => collection.itemIds.contains(item.id))
            .toList();

        return _buildScaffold(context, collection, collectionItems, allItems);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, WardrobeCollection collection, List<ClothingItem> collectionItems, List<ClothingItem> allItems) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (collection.icon != null) ...[
              Text(collection.icon!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                collection.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(collection),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection Info
          if (collection.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${collectionItems.length} items',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

          // Items Grid
          Expanded(
            child: collectionItems.isEmpty
                ? _EmptyState(
                    onAddItems: () => _showAddItemsSheet(collection, allItems),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: collectionItems.length,
                    itemBuilder: (_, i) => _ItemCard(
                      item: collectionItems[i],
                      onTap: () => _showItemDetail(collectionItems[i]),
                      onRemove: () => _confirmRemoveItem(collection, collectionItems[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemsSheet(collection, allItems),
        icon: const Icon(Icons.add),
        label: const Text('Add Items'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showEditDialog(WardrobeCollection collection) {
    final nameController = TextEditingController(text: collection.name);
    final descController = TextEditingController(text: collection.description);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(collectionProvider.notifier).updateCollection(
                    collection.id,
                    name: nameController.text,
                    description: descController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddItemsSheet(WardrobeCollection collection, List<ClothingItem> allItems) {
    // Items not yet in this collection
    final availableItems = allItems
        .where((item) => !collection.itemIds.contains(item.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                  'Add Items to Collection',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: availableItems.isEmpty
                    ? Center(
                        child: Text(
                          'All items already in collection',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: availableItems.length,
                        itemBuilder: (_, i) => _AddableItemCard(
                          item: availableItems[i],
                          onAdd: () {
                            ref.read(collectionProvider.notifier).addItemToCollection(
                                  collection.id,
                                  availableItems[i].id,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${availableItems[i].name}" to collection'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(ClothingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClothingDetailModal(
        item: item,
        onEdit: () {
          Navigator.pop(context);
          context.push('/wardrobe/add', extra: item);
        },
        onDelete: () {
          Navigator.pop(context);
          ref.read(wardrobeProvider.notifier).removeItem(item.id);
        },
        onToggleFavorite: () {
          ref.read(wardrobeProvider.notifier).toggleFavorite(item.id);
        },
        onMarkWorn: () {
          ref.read(wardrobeProvider.notifier).markWorn(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Marked "${item.name}" as worn today!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _confirmRemoveItem(WardrobeCollection collection, ClothingItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from Collection'),
        content: Text('Remove "${item.name}" from this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(collectionProvider.notifier).removeItemFromCollection(
                    collection.id,
                    item.id,
                  );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImage()),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.color.isEmpty ? item.category.displayName : item.color,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_circle,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return Image.network(
        item.storageImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => _iconFallback(),
      );
    }
    if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return kIsWeb
          ? Image.network(item.localImagePath!, fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _iconFallback())
          : Image.file(File(item.localImagePath!), fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _iconFallback());
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Center(
        child: Text(item.category.icon, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _AddableItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onAdd;

  const _AddableItemCard({
    required this.item,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(child: _buildImage()),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 30,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.storageImageUrl != null && item.storageImageUrl!.isNotEmpty) {
      return Image.network(
        item.storageImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => _iconFallback(),
      );
    }
    if (item.localImagePath != null && item.localImagePath!.isNotEmpty) {
      return kIsWeb
          ? Image.network(item.localImagePath!, fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _iconFallback())
          : Image.file(File(item.localImagePath!), fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _iconFallback());
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Center(
        child: Text(item.category.icon, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddItems;

  const _EmptyState({required this.onAddItems});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No items in this collection',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add clothing items to build\nyour capsule wardrobe',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddItems,
            icon: const Icon(Icons.add),
            label: const Text('Add Items'),
          ),
        ],
      ),
    );
  }
}
