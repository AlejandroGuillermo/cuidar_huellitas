import 'package:flutter/material.dart';

class FoodCatalogItem {
  final String id;
  final String emoji;
  final String name;
  final int hungerPoints;
  final int price;
  final Color color;

  const FoodCatalogItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.hungerPoints,
    required this.price,
    required this.color,
  });
}

class FoodCatalog {
  static const double bagUnits = 100.0;
  static const double bagUsagePerPlatePercent = 0.2;

  static const List<FoodCatalogItem> items = [
    FoodCatalogItem(
      id: 'carne',
      emoji: '🥩',
      name: 'Carne',
      hungerPoints: 30,
      price: 33,
      color: Color(0xFFF07A94),
    ),
    FoodCatalogItem(
      id: 'hueso',
      emoji: '🍖',
      name: 'Hueso',
      hungerPoints: 25,
      price: 27,
      color: Color(0xFFA3FF88),
    ),
    FoodCatalogItem(
      id: 'zanahoria',
      emoji: '🥕',
      name: 'Zanahoria',
      hungerPoints: 15,
      price: 16,
      color: Color(0xFF8AE670),
    ),
    FoodCatalogItem(
      id: 'pescado',
      emoji: '🐟',
      name: 'Pescado',
      hungerPoints: 28,
      price: 29,
      color: Color(0xFF708BE6),
    ),
    FoodCatalogItem(
      id: 'pollo',
      emoji: '🍗',
      name: 'Pollo',
      hungerPoints: 26,
      price: 28,
      color: Color(0xFF8AA2FF),
    ),
    FoodCatalogItem(
      id: 'leche',
      emoji: '🥛',
      name: 'Leche',
      hungerPoints: 10,
      price: 13,
      color: Color(0xFFB5E8FF),
    ),
    FoodCatalogItem(
      id: 'croquetas',
      emoji: '🟤',
      name: 'Croquetas',
      hungerPoints: 7,
      price: 11,
      color: Color(0xFFB68E5C),
    ),
    FoodCatalogItem(
      id: 'galleta',
      emoji: '🍪',
      name: 'Galleta',
      hungerPoints: 7,
      price: 11,
      color: Color(0xFFD4A96A),
    ),
  ];

  static const Map<String, double> _starterInventory = {
    'carne': 200.0,
    'hueso': 100.0,
    'croquetas': 1000.0,
  };

  static FoodCatalogItem? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Map<String, double> starterInventory() {
    return Map<String, double>.from(_starterInventory);
  }

  static Map<String, bool> starterUnlocked() {
    final unlocked = <String, bool>{};
    for (final item in items) {
      unlocked[item.id] = _starterInventory.containsKey(item.id);
    }
    return unlocked;
  }
}
