import '../../core/food_catalog.dart';

class AlimentarState {
  const AlimentarState({
    this.activeBag,
    this.plateLevel = 0,
    this.loading = true,
    this.coins = 0,
    this.plateFoodId,
    this.plateEmoji = '🥩',
    this.foodInPlate = const <String>[],
    this.inventoryUnits = const <String, double>{},
    this.unlockedFoods = const <String, bool>{},
    this.isPouring = false,
  });

  final FoodCatalogItem? activeBag;
  final double plateLevel;
  final bool loading;
  final int coins;
  final String? plateFoodId;
  final String plateEmoji;
  final List<String> foodInPlate;
  final Map<String, double> inventoryUnits;
  final Map<String, bool> unlockedFoods;
  final bool isPouring;

  AlimentarState copyWith({
    FoodCatalogItem? activeBag,
    bool clearActiveBag = false,
    double? plateLevel,
    bool? loading,
    int? coins,
    String? plateFoodId,
    bool clearPlateFoodId = false,
    String? plateEmoji,
    List<String>? foodInPlate,
    Map<String, double>? inventoryUnits,
    Map<String, bool>? unlockedFoods,
    bool? isPouring,
  }) {
    return AlimentarState(
      activeBag: clearActiveBag ? null : (activeBag ?? this.activeBag),
      plateLevel: plateLevel ?? this.plateLevel,
      loading: loading ?? this.loading,
      coins: coins ?? this.coins,
      plateFoodId: clearPlateFoodId ? null : (plateFoodId ?? this.plateFoodId),
      plateEmoji: plateEmoji ?? this.plateEmoji,
      foodInPlate: foodInPlate ?? this.foodInPlate,
      inventoryUnits: inventoryUnits ?? this.inventoryUnits,
      unlockedFoods: unlockedFoods ?? this.unlockedFoods,
      isPouring: isPouring ?? this.isPouring,
    );
  }
}
