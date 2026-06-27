import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_ingredient.dart';

class ShoppingItem {
  final String id;
  final String name;
  double quantity;
  final String unit;
  final String category;
  bool isDone;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'isDone': isDone,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? '',
      category: map['category'] ?? 'Pantry & Grains',
      isDone: map['isDone'] ?? false,
    );
  }
}

class ShoppingListProvider with ChangeNotifier {
  List<ShoppingItem> _items = [];
  static const String _storageKey = 'cashfit_shopping_list';

  List<ShoppingItem> get items => _items;
  List<ShoppingItem> get pendingItems => _items.where((i) => !i.isDone).toList();
  List<ShoppingItem> get completedItems => _items.where((i) => i.isDone).toList();

  ShoppingListProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _items = decoded.map((item) => ShoppingItem.fromMap(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading shopping list: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(_items.map((i) => i.toMap()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint("Error saving shopping list: $e");
    }
  }

  static String detectCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('chicken') || n.contains('beef') || n.contains('turkey') || 
        n.contains('salmon') || n.contains('tuna') || n.contains('steak') || 
        n.contains('fish') || n.contains('meat') || n.contains('egg')) {
      return 'Meat, Seafood & Eggs';
    } else if (n.contains('spinach') || n.contains('banana') || n.contains('apple') || 
               n.contains('broccoli') || n.contains('avocado') || n.contains('berry') || 
               n.contains('tomato') || n.contains('onion') || n.contains('lemon') || 
               n.contains('fruit') || n.contains('vegetable')) {
      return 'Produce';
    } else if (n.contains('milk') || n.contains('yogurt') || n.contains('cheese') || 
               n.contains('whey') || n.contains('protein powder') || n.contains('butter')) {
      return 'Dairy & Protein';
    }
    return 'Pantry & Grains';
  }

  void addItem(String name, double quantity, String unit, String category, {bool notify = true}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final cat = category.isEmpty ? detectCategory(cleanName) : category;
    final existingIndex = _items.indexWhere(
      (i) => i.name.toLowerCase() == cleanName.toLowerCase() && i.unit.toLowerCase() == unit.trim().toLowerCase(),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        ShoppingItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${cleanName.replaceAll(' ', '_')}',
          name: cleanName,
          quantity: quantity,
          unit: unit.trim(),
          category: cat,
        ),
      );
    }
    if (notify) {
      notifyListeners();
      _saveToStorage();
    }
  }

  void addIngredients(List<MealIngredient> ingredients) {
    for (var ing in ingredients) {
      addItem(
        ing.ingredient.name,
        ing.quantity,
        ing.unit,
        detectCategory(ing.ingredient.name),
        notify: false,
      );
    }
    notifyListeners();
    _saveToStorage();
  }

  void toggleItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index].isDone = !_items[index].isDone;
      notifyListeners();
      _saveToStorage();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _saveToStorage();
  }

  void clearCompleted() {
    _items.removeWhere((i) => i.isDone);
    notifyListeners();
    _saveToStorage();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    _saveToStorage();
  }
}
