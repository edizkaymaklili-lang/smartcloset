import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stil_asist/core/enums/clothing_category.dart';
import 'package:stil_asist/features/profile/presentation/providers/profile_provider.dart';
import 'package:stil_asist/features/wardrobe/domain/entities/clothing_item.dart';
import 'package:stil_asist/features/wardrobe/presentation/providers/wardrobe_provider.dart';

ClothingItem _item(String id, {String name = 'Test Item'}) => ClothingItem(
      id: id,
      name: name,
      category: ClothingCategory.tops,
      color: 'red',
      addedAt: DateTime(2024, 1, 1),
    );

Future<ProviderContainer> _makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('WardrobeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      container = await _makeContainer();
    });

    tearDown(() => container.dispose());

    test('starts with an empty wardrobe', () {
      expect(container.read(wardrobeProvider), isEmpty);
    });

    test('addItem adds item to state', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      expect(container.read(wardrobeProvider).length, 1);
      expect(container.read(wardrobeProvider).first.id, '1');
    });

    test('addItem multiple items preserves order', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      container.read(wardrobeProvider.notifier).addItem(_item('2'));
      container.read(wardrobeProvider.notifier).addItem(_item('3'));

      final ids = container.read(wardrobeProvider).map((i) => i.id).toList();
      expect(ids, ['1', '2', '3']);
    });

    test('removeItem removes the correct item', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      container.read(wardrobeProvider.notifier).addItem(_item('2'));
      container.read(wardrobeProvider.notifier).removeItem('1');

      final items = container.read(wardrobeProvider);
      expect(items.length, 1);
      expect(items.first.id, '2');
    });

    test('removeItem on non-existent id leaves state unchanged', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      container.read(wardrobeProvider.notifier).removeItem('999');
      expect(container.read(wardrobeProvider).length, 1);
    });

    test('toggleFavorite sets isFavorite to true', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      container.read(wardrobeProvider.notifier).toggleFavorite('1');
      expect(container.read(wardrobeProvider).first.isFavorite, isTrue);
    });

    test('toggleFavorite twice reverts to false', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1'));
      container.read(wardrobeProvider.notifier).toggleFavorite('1');
      container.read(wardrobeProvider.notifier).toggleFavorite('1');
      expect(container.read(wardrobeProvider).first.isFavorite, isFalse);
    });

    test('updateItem replaces item with matching id', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1', name: 'Old'));
      final updated = _item('1', name: 'New');
      container.read(wardrobeProvider.notifier).updateItem(updated);

      expect(container.read(wardrobeProvider).first.name, 'New');
    });

    test('updateItem does not affect other items', () {
      container.read(wardrobeProvider.notifier).addItem(_item('1', name: 'One'));
      container.read(wardrobeProvider.notifier).addItem(_item('2', name: 'Two'));
      container.read(wardrobeProvider.notifier).updateItem(_item('1', name: 'Updated'));

      final items = container.read(wardrobeProvider);
      expect(items.firstWhere((i) => i.id == '1').name, 'Updated');
      expect(items.firstWhere((i) => i.id == '2').name, 'Two');
    });

    test('state persists to SharedPreferences and loads on new container', () async {
      container.read(wardrobeProvider.notifier).addItem(_item('1', name: 'Persisted'));
      container.dispose();

      // New container with same prefs instance
      final prefs = await SharedPreferences.getInstance();
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      final items = container2.read(wardrobeProvider);
      expect(items.length, 1);
      expect(items.first.name, 'Persisted');
    });
  });
}
