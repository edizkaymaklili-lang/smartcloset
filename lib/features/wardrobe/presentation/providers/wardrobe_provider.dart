import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/clothing_item.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../main.dart' show firebaseAvailableProvider;

final wardrobeProvider = NotifierProvider<WardrobeNotifier, List<ClothingItem>>(() {
  return WardrobeNotifier();
});

class WardrobeNotifier extends Notifier<List<ClothingItem>> {
  static const _key = 'wardrobe_items';

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _userId => ref.read(authProvider).userId;
  bool get _firebaseReady => ref.read(firebaseAvailableProvider);

  @override
  List<ClothingItem> build() {
    // Sync from Firestore when Firebase becomes available
    ref.listen(firebaseAvailableProvider, (_, isReady) {
      if (isReady) Future.microtask(_syncFromFirestore);
    });
    // Re-sync when user logs in / changes
    ref.listen(authProvider, (prev, next) {
      if (prev?.userId != next.userId && next.userId != null) {
        Future.microtask(_syncFromFirestore);
      }
    });
    // Also sync immediately if Firebase + auth are already ready at build time
    if (_firebaseReady && _userId != null) {
      Future.microtask(_syncFromFirestore);
    }
    return _loadFromPrefs();
  }

  // ── Local persistence ────────────────────────────────────────────────────

  List<ClothingItem> _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => ClothingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_key, jsonEncode(state.map((i) => i.toJson()).toList()));
  }

  // ── Firestore sync ───────────────────────────────────────────────────────

  Future<void> _syncFromFirestore() async {
    if (!_firebaseReady) return;
    final userId = _userId;
    if (userId == null) return;

    try {
      final snapshot = await _db
          .collection('wardrobe')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        // First time — migrate local items to Firestore
        if (state.isNotEmpty) await _pushAllToFirestore(userId);
        return;
      }

      final items = snapshot.docs
          .map((doc) => ClothingItem.fromJson(doc.data()))
          .toList();

      state = items;
      _persist();
    } catch (e) {
      debugPrint('Wardrobe Firestore sync error: $e');
    }
  }

  Future<void> _pushAllToFirestore(String userId) async {
    final batch = _db.batch();
    for (final item in state) {
      batch.set(
        _db.collection('wardrobe').doc(item.id),
        {...item.toJson(), 'userId': userId},
      );
    }
    await batch.commit();
  }

  Future<void> _writeToFirestore(ClothingItem item) async {
    if (!_firebaseReady) return;
    final userId = _userId;
    if (userId == null) return;
    try {
      await _db
          .collection('wardrobe')
          .doc(item.id)
          .set({...item.toJson(), 'userId': userId});
    } catch (e) {
      debugPrint('Wardrobe write Firestore error: $e');
    }
  }

  Future<void> _deleteFromFirestore(String id) async {
    if (!_firebaseReady) return;
    try {
      await _db.collection('wardrobe').doc(id).delete();
    } catch (e) {
      debugPrint('Wardrobe delete Firestore error: $e');
    }
  }

  // ── Public mutations (sync both local + Firestore) ───────────────────────

  void addItem(ClothingItem item) {
    state = [...state, item];
    _persist();
    _writeToFirestore(item);
  }

  void updateItem(ClothingItem updatedItem) {
    state = state
        .map((i) => i.id == updatedItem.id ? updatedItem : i)
        .toList();
    _persist();
    _writeToFirestore(updatedItem);
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
    _persist();
    _deleteFromFirestore(id);
  }

  void toggleFavorite(String id) {
    state = state
        .map((i) => i.id == id ? i.copyWith(isFavorite: !i.isFavorite) : i)
        .toList();
    _persist();
    final item = state.firstWhere((i) => i.id == id);
    _writeToFirestore(item);
  }

  void markWorn(String id) {
    state = state
        .map((i) => i.id == id ? i.copyWith(lastWorn: DateTime.now()) : i)
        .toList();
    _persist();
    final item = state.firstWhere((i) => i.id == id);
    _writeToFirestore(item);
  }

  void updateStorageUrl(String id, String url) {
    state = state
        .map((i) => i.id == id ? i.copyWith(storageImageUrl: url) : i)
        .toList();
    _persist();
    final item = state.firstWhere((i) => i.id == id);
    _writeToFirestore(item);
  }
}
