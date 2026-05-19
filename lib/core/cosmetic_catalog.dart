class CosmeticCatalogItem {
  final String id;
  final String emoji;
  final String name;
  final int price;
  final String slot;

  const CosmeticCatalogItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.slot,
  });
}

class CosmeticCatalog {
  static const List<CosmeticCatalogItem> items = [
    CosmeticCatalogItem(
      id: 'gorro_azul',
      emoji: '🧢',
      name: 'Gorro azul',
      price: 80,
      slot: 'cabeza',
    ),
    CosmeticCatalogItem(
      id: 'sombrero',
      emoji: '🎩',
      name: 'Sombrero',
      price: 110,
      slot: 'cabeza',
    ),
    CosmeticCatalogItem(
      id: 'corona',
      emoji: '👑',
      name: 'Corona',
      price: 140,
      slot: 'cabeza',
    ),
    CosmeticCatalogItem(
      id: 'mono_rosa',
      emoji: '🎀',
      name: 'Mono rosa',
      price: 90,
      slot: 'cabeza',
    ),
    CosmeticCatalogItem(
      id: 'lentes_sol',
      emoji: '🕶️',
      name: 'Lentes de sol',
      price: 130,
      slot: 'cabeza',
    ),
    CosmeticCatalogItem(
      id: 'flor_rosa',
      emoji: '🌸',
      name: 'Flor rosa',
      price: 100,
      slot: 'cabeza',
    ),
  ];

  static CosmeticCatalogItem? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static String? headEmojiFor(String? id) {
    final item = byId(id);
    if (item == null) return null;
    return item.slot == 'cabeza' ? item.emoji : null;
  }

  static Map<String, bool> starterInventory() {
    final map = <String, bool>{};
    for (final item in items) {
      map[item.id] = false;
    }
    return map;
  }
}
