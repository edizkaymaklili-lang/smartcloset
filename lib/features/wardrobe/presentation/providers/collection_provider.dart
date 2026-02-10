import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/wardrobe_collection.dart';

const _collectionsKey = 'wardrobe_collections';
const _uuid = Uuid();

final collectionProvider =
    AsyncNotifierProvider<CollectionNotifier, List<WardrobeCollection>>(
  CollectionNotifier.new,
);

class CollectionNotifier extends AsyncNotifier<List<WardrobeCollection>> {
  @override
  Future<List<WardrobeCollection>> build() async {
    return await _loadCollections();
  }

  Future<List<WardrobeCollection>> _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_collectionsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => WardrobeCollection.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<void> _saveCollections(List<WardrobeCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(collections.map((c) => c.toJson()).toList());
    await prefs.setString(_collectionsKey, jsonString);
  }

  List<WardrobeCollection> _getCurrentState() {
    return state.when(
      data: (collections) => collections,
      loading: () => [],
      error: (_, _) => [],
    );
  }

  Future<void> addCollection(String name, {String? description, String? icon}) async {
    final currentState = _getCurrentState();
    final newCollection = WardrobeCollection(
      id: _uuid.v4(),
      name: name,
      description: description ?? '',
      itemIds: [],
      createdAt: DateTime.now(),
      icon: icon,
    );
    final newState = [...currentState, newCollection];
    state = AsyncValue.data(newState);
    await _saveCollections(newState);
  }

  Future<void> updateCollection(String id, {String? name, String? description, String? icon}) async {
    final currentState = _getCurrentState();
    final newState = currentState.map((c) {
      if (c.id == id) {
        return c.copyWith(
          name: name ?? c.name,
          description: description ?? c.description,
          icon: icon ?? c.icon,
        );
      }
      return c;
    }).toList();
    state = AsyncValue.data(newState);
    await _saveCollections(newState);
  }

  Future<void> deleteCollection(String id) async {
    final currentState = _getCurrentState();
    final newState = currentState.where((c) => c.id != id).toList();
    state = AsyncValue.data(newState);
    await _saveCollections(newState);
  }

  Future<void> addItemToCollection(String collectionId, String itemId) async {
    final currentState = _getCurrentState();
    final newState = currentState.map((c) {
      if (c.id == collectionId && !c.itemIds.contains(itemId)) {
        return c.copyWith(itemIds: [...c.itemIds, itemId]);
      }
      return c;
    }).toList();
    state = AsyncValue.data(newState);
    await _saveCollections(newState);
  }

  Future<void> removeItemFromCollection(String collectionId, String itemId) async {
    final currentState = _getCurrentState();
    final newState = currentState.map((c) {
      if (c.id == collectionId) {
        return c.copyWith(
          itemIds: c.itemIds.where((id) => id != itemId).toList(),
        );
      }
      return c;
    }).toList();
    state = AsyncValue.data(newState);
    await _saveCollections(newState);
  }

  List<WardrobeCollection> getCollectionsForItem(String itemId) {
    final currentState = _getCurrentState();
    return currentState.where((c) => c.itemIds.contains(itemId)).toList();
  }
}
