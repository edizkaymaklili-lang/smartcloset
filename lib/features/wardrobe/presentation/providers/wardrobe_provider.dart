import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/clothing_item.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final wardrobeProvider = NotifierProvider<WardrobeNotifier, List<ClothingItem>>(() {
  return WardrobeNotifier();
});

class WardrobeNotifier extends Notifier<List<ClothingItem>> {
  static const _key = 'wardrobe_items';

  @override
  List<ClothingItem> build() {
    return _loadFromPrefs();
  }

  List<ClothingItem> _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => ClothingItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(state.map((i) => i.toJson()).toList());
    prefs.setString(_key, jsonStr);
  }

  void addItem(ClothingItem item) {
    state = [...state, item];
    _persist();
  }

  void updateItem(ClothingItem updatedItem) {
    state = state.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    _persist();
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
    _persist();
  }

  void toggleFavorite(String id) {
    state = state.map((i) {
      return i.id == id ? i.copyWith(isFavorite: !i.isFavorite) : i;
    }).toList();
    _persist();
  }

  void markWorn(String id) {
    state = state.map((i) {
      return i.id == id ? i.copyWith(lastWorn: DateTime.now()) : i;
    }).toList();
    _persist();
  }

  void updateStorageUrl(String id, String url) {
    state = state.map((i) {
      return i.id == id ? i.copyWith(storageImageUrl: url) : i;
    }).toList();
    _persist();
  }
}
