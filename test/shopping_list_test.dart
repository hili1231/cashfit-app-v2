import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashfit/providers/shopping_list_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShoppingListProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Adds custom items correctly', () {
      final provider = ShoppingListProvider();
      provider.addItem('Oats', 2.0, 'cups', 'Pantry');

      expect(provider.items.length, 1);
      expect(provider.items.first.name, 'Oats');
      expect(provider.items.first.quantity, 2.0);
      expect(provider.items.first.isDone, false);
    });

    test('Aggregates duplicate items', () {
      final provider = ShoppingListProvider();
      provider.addItem('Eggs', 6.0, 'pcs', 'Dairy');
      provider.addItem('Eggs', 6.0, 'pcs', 'Dairy');

      expect(provider.items.length, 1);
      expect(provider.items.first.quantity, 12.0);
    });

    test('Toggles item done state', () {
      final provider = ShoppingListProvider();
      provider.addItem('Chicken Breast', 500.0, 'g', 'Meat & Seafood');
      final itemId = provider.items.first.id;

      provider.toggleItem(itemId);
      expect(provider.items.first.isDone, true);

      provider.clearCompleted();
      expect(provider.items.length, 0);
    });
  });
}
