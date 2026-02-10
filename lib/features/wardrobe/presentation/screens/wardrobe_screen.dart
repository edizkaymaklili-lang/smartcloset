import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/clothing_category.dart';
import '../../domain/entities/clothing_item.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/wardrobe_stats_card.dart';
import '../widgets/clothing_detail_modal.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

enum SortOption {
  newestFirst,
  oldestFirst,
  mostWorn,
  rarelyWorn,
  alphabeticalAZ,
  alphabeticalZA,
}

extension SortOptionExt on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.mostWorn:
        return 'Most Worn';
      case SortOption.rarelyWorn:
        return 'Rarely Worn';
      case SortOption.alphabeticalAZ:
        return 'A → Z';
      case SortOption.alphabeticalZA:
        return 'Z → A';
    }
  }
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  ClothingCategory? _selectedCategory;
  String _searchQuery = '';
  String? _filterType; // 'favorites', 'rarely-worn', 'new'
  String? _selectedColor;
  SortOption _sortOption = SortOption.newestFirst;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(wardrobeProvider);

    // Apply filters
    var filtered = items;

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((i) => i.category == _selectedCategory).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) =>
        i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        i.color.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        i.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Color filter
    if (_selectedColor != null) {
      filtered = filtered.where((i) =>
        i.color.toLowerCase().contains(_selectedColor!.toLowerCase())
      ).toList();
    }

    // Special filters
    if (_filterType == 'favorites') {
      filtered = filtered.where((i) => i.isFavorite).toList();
    } else if (_filterType == 'rarely-worn') {
      filtered = filtered.where((i) {
        if (i.lastWorn == null) return true;
        return DateTime.now().difference(i.lastWorn!).inDays > 30;
      }).toList();
    } else if (_filterType == 'new') {
      filtered = filtered.where((i) => i.lastWorn == null).toList();
    }

    // Apply sorting
    filtered = List.from(filtered); // Create mutable copy
    switch (_sortOption) {
      case SortOption.newestFirst:
        filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SortOption.oldestFirst:
        filtered.sort((a, b) => a.addedAt.compareTo(b.addedAt));
        break;
      case SortOption.mostWorn:
        filtered.sort((a, b) {
          if (a.lastWorn == null && b.lastWorn == null) return 0;
          if (a.lastWorn == null) return 1;
          if (b.lastWorn == null) return -1;
          return b.lastWorn!.compareTo(a.lastWorn!);
        });
        break;
      case SortOption.rarelyWorn:
        filtered.sort((a, b) {
          if (a.lastWorn == null && b.lastWorn == null) return 0;
          if (a.lastWorn == null) return -1;
          if (b.lastWorn == null) return 1;
          return a.lastWorn!.compareTo(b.lastWorn!);
        });
        break;
      case SortOption.alphabeticalAZ:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.alphabeticalZA:
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wardrobe (${items.length})'),
        actions: [
          // Sort dropdown
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (_) => SortOption.values.map((option) {
              return PopupMenuItem<SortOption>(
                value: option,
                child: Row(
                  children: [
                    if (_sortOption == option)
                      const Icon(Icons.check, color: AppColors.primary, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(option.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Dashboard
          if (items.isNotEmpty) WardrobeStatsCard(items: items),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, color, category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter Chips - Categories
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...ClothingCategory.values.map((cat) {
                  final count = items.where((i) => i.category == cat).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Text(cat.icon),
                      label: Text('${cat.displayName} ($count)'),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() {
                        _selectedCategory =
                            _selectedCategory == cat ? null : cat;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Color Filters
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _ColorFilterChip(
                  color: null,
                  label: 'All Colors',
                  isSelected: _selectedColor == null,
                  onTap: () => setState(() => _selectedColor = null),
                ),
                const SizedBox(width: 8),
                ...[
                  ('Red', Colors.red),
                  ('Blue', Colors.blue),
                  ('Black', Colors.black),
                  ('White', Colors.white),
                  ('Green', Colors.green),
                  ('Yellow', Colors.yellow),
                  ('Pink', Colors.pink),
                  ('Purple', Colors.purple),
                  ('Brown', Colors.brown),
                  ('Gray', Colors.grey),
                ].map((colorData) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ColorFilterChip(
                      color: colorData.$2,
                      label: colorData.$1,
                      isSelected: _selectedColor == colorData.$1,
                      onTap: () => setState(() {
                        _selectedColor = _selectedColor == colorData.$1 ? null : colorData.$1;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Special Filters
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                FilterChip(
                  avatar: const Icon(Icons.favorite, size: 16),
                  label: Text('Favorites (${items.where((i) => i.isFavorite).length})'),
                  selected: _filterType == 'favorites',
                  onSelected: (_) => setState(() {
                    _filterType = _filterType == 'favorites' ? null : 'favorites';
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.access_time, size: 16),
                  label: Text('Rarely Worn (${items.where((i) => i.lastWorn == null || DateTime.now().difference(i.lastWorn!).inDays > 30).length})'),
                  selected: _filterType == 'rarely-worn',
                  onSelected: (_) => setState(() {
                    _filterType = _filterType == 'rarely-worn' ? null : 'rarely-worn';
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.fiber_new, size: 16),
                  label: Text('New Items (${items.where((i) => i.lastWorn == null).length})'),
                  selected: _filterType == 'new',
                  onSelected: (_) => setState(() {
                    _filterType = _filterType == 'new' ? null : 'new';
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    hasItems: items.isNotEmpty,
                    onAdd: () => context.push('/wardrobe/add'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ClothingCard(
                      item: filtered[i],
                      onTap: () => _showQuickView(filtered[i]),
                      onDelete: () => _confirmDelete(filtered[i]),
                      onFavorite: () => ref
                          .read(wardrobeProvider.notifier)
                          .toggleFavorite(filtered[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'collections',
            onPressed: () => context.push('/wardrobe/collections'),
            backgroundColor: AppColors.secondary,
            tooltip: 'Collections',
            child: const Icon(Icons.collections_outlined, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'style_board',
            onPressed: () => context.push('/wardrobe/style-board'),
            backgroundColor: AppColors.secondary,
            tooltip: 'Style Board',
            child: const Icon(Icons.style, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'try_on',
            onPressed: () => context.push('/wardrobe/try-on'),
            backgroundColor: AppColors.secondary,
            tooltip: 'Virtual Try-On',
            child: const Icon(Icons.checkroom, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_item',
            onPressed: () => context.push('/wardrobe/add'),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Item', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickView(ClothingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClothingDetailModal(
        item: item,
        onEdit: () {
          Navigator.pop(context); // Close the detail modal first
          context.push('/wardrobe/add', extra: item);
        },
        onDelete: () => _confirmDelete(item),
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

  void _confirmDelete(ClothingItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(wardrobeProvider.notifier).removeItem(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const _ClothingCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceWorn = item.lastWorn != null
        ? DateTime.now().difference(item.lastWorn!).inDays
        : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorite
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Rarely worn badge
                  if (daysSinceWorn != null && daysSinceWorn > 30)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${daysSinceWorn}d',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
      // Web cannot access local file paths - show fallback icon
      // Images are uploaded to Firebase Storage for web support
      if (kIsWeb) {
        return _iconFallback();
      }
      return Image.file(File(item.localImagePath!), fit: BoxFit.cover, errorBuilder: (ctx, e, st) => _iconFallback());
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

class _EmptyState extends StatelessWidget {
  final bool hasItems;
  final VoidCallback onAdd;

  const _EmptyState({required this.hasItems, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            hasItems ? 'No items in this category' : 'Your wardrobe is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (!hasItems) ...[
            const SizedBox(height: 8),
            Text(
              'Add your clothing items to get\npersonalized outfit recommendations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorFilterChip extends StatelessWidget {
  final Color? color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorFilterChip({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
