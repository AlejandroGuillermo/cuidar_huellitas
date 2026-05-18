import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Models/inventario_comida_model.dart';
import '../../Models/mascota_model.dart';
import '../../core/food_catalog.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'alimentar_state.dart';

class AlimentarCubit extends Cubit<AlimentarState> {
  AlimentarCubit({
    InventoryRepository? inventoryRepository,
    UserRepository? userRepository,
  }) : _inventoryRepository = inventoryRepository ?? InventoryRepository(),
       _userRepository = userRepository ?? UserRepository(),
       super(const AlimentarState());

  final InventoryRepository _inventoryRepository;
  final UserRepository _userRepository;

  Timer? _pouringTimer;

  Future<void> initialize({required MascotaModel? pet}) async {
    _syncFromPetInternal(pet);

    final userId = _inventoryRepository.currentUserId;
    if (userId == null) {
      _emitIfOpen(state.copyWith(loading: false));
      return;
    }

    try {
      await _inventoryRepository.ensureDefaultInventory(userId);
      if (isClosed) return;
      await _userRepository.normalizeLegacyUserDoc(userId);
      if (isClosed) return;
      final inventory = await _inventoryRepository.loadFoodInventory(userId);
      if (isClosed) return;
      final coins = await _userRepository.loadCoins(userId);
      if (isClosed) return;

      _emitIfOpen(
        state.copyWith(
          coins: coins,
          inventoryUnits: Map<String, double>.from(inventory.cantidades),
          unlockedFoods: Map<String, bool>.from(inventory.desbloqueados),
          loading: false,
        ),
      );
    } catch (_) {
      _emitIfOpen(state.copyWith(loading: false));
    }
  }

  void syncFromPet(MascotaModel? pet) {
    if (state.isPouring) return;
    _syncFromPetInternal(pet);
  }

  void _syncFromPetInternal(MascotaModel? pet) {
    if (pet == null) return;

    final nextPlateFoodId = pet.platoAlimentoId.isEmpty
        ? null
        : pet.platoAlimentoId;
    final nextEmoji = pet.platoEmoji.isNotEmpty
        ? pet.platoEmoji
        : (FoodCatalog.byId(nextPlateFoodId)?.emoji ?? state.plateEmoji);
    final nextPlateLevel = pet.nivelPlato;

    _emitIfOpen(
      state.copyWith(
        plateLevel: nextPlateLevel,
        plateFoodId: nextPlateFoodId,
        clearPlateFoodId: nextPlateFoodId == null,
        plateEmoji: nextEmoji,
        foodInPlate: _foodPieces(nextPlateLevel, nextEmoji),
      ),
    );
  }

  String? selectFood(FoodCatalogItem food, {required bool eating}) {
    if (eating) return null;

    if (!_isFoodUnlocked(food.id)) {
      return 'Ese alimento está bloqueado. Cómpralo en Tienda.';
    }

    if ((state.inventoryUnits[food.id] ?? 0.0) <= 0.0) {
      return 'No tienes bolsas de ${food.name}.';
    }

    if (state.plateLevel > 0 &&
        state.plateFoodId != null &&
        state.plateFoodId != food.id) {
      return 'Primero termina el alimento que ya está en el plato.';
    }

    _emitIfOpen(
      state.copyWith(
        activeBag: food,
        plateFoodId: state.plateFoodId ?? food.id,
        plateEmoji: food.emoji,
      ),
    );
    return null;
  }

  void removeBag() {
    _emitIfOpen(state.copyWith(clearActiveBag: true));
  }

  void clearPlateLocally() {
    _emitIfOpen(
      state.copyWith(
        plateLevel: 0,
        clearPlateFoodId: true,
        foodInPlate: const <String>[],
      ),
    );
  }

  void startPouring({required bool eating}) {
    final bag = state.activeBag;
    if (bag == null ||
        eating ||
        state.plateLevel >= 100 ||
        _pouringTimer != null ||
        !_canUseFood(bag.id)) {
      return;
    }

    if (state.plateFoodId != null &&
        state.plateFoodId != bag.id &&
        state.plateLevel > 0) {
      return;
    }

    _emitIfOpen(
      state.copyWith(
        plateFoodId: bag.id,
        plateEmoji: bag.emoji,
        isPouring: true,
      ),
    );

    _pouringTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (isClosed) {
        _pouringTimer?.cancel();
        _pouringTimer = null;
        return;
      }

      final currentState = state;
      final currentUnits = currentState.inventoryUnits[bag.id] ?? 0.0;

      if (currentUnits <= 0.0 || currentState.plateLevel >= 100) {
        unawaited(stopPouring());
        return;
      }

      const plateStep = 2.0;
      final plateAvailable = 100.0 - currentState.plateLevel;
      final plateIncrease = min(plateStep, plateAvailable);
      final bagCost = plateIncrease * FoodCatalog.bagUsagePerPlatePercent;

      final nextInventory = Map<String, double>.from(
        currentState.inventoryUnits,
      );
      double nextPlateLevel = currentState.plateLevel;

      if (currentUnits >= bagCost) {
        nextPlateLevel = (currentState.plateLevel + plateIncrease).clamp(
          0,
          100,
        );
        nextInventory[bag.id] = (currentUnits - bagCost)
            .clamp(0, 99999)
            .toDouble();
      } else {
        final possibleIncrease =
            currentUnits / FoodCatalog.bagUsagePerPlatePercent;
        nextPlateLevel = (currentState.plateLevel + possibleIncrease).clamp(
          0,
          100,
        );
        nextInventory[bag.id] = 0.0;
      }

      _emitIfOpen(
        currentState.copyWith(
          plateLevel: nextPlateLevel,
          inventoryUnits: nextInventory,
          foodInPlate: _foodPieces(nextPlateLevel, currentState.plateEmoji),
          isPouring: true,
        ),
      );

      if ((nextInventory[bag.id] ?? 0.0) <= 0.0 || nextPlateLevel >= 100) {
        unawaited(stopPouring());
      }
    });
  }

  Future<void> stopPouring() async {
    _pouringTimer?.cancel();
    _pouringTimer = null;
    if (state.isPouring) {
      _emitIfOpen(state.copyWith(isPouring: false));
    }
  }

  void _emitIfOpen(AlimentarState nextState) {
    if (isClosed) return;
    emit(nextState);
  }

  Future<void> persistInventoryAndPlate({
    required bool eating,
    required Future<void> Function({
      required double nivelPlato,
      required String? platoAlimentoId,
      required bool clearPlatoAlimentoId,
      required String? platoEmoji,
      required bool clearPlatoEmoji,
      required bool platoComiendo,
    })
    persistPlate,
  }) async {
    final userId = _inventoryRepository.currentUserId;
    if (userId != null) {
      await _inventoryRepository.saveFoodInventoryAndCoins(
        userId: userId,
        coins: state.coins,
        inventory: InventarioComidaModel(
          cantidades: state.inventoryUnits,
          desbloqueados: state.unlockedFoods,
        ),
      );
    }

    await persistPlate(
      nivelPlato: state.plateLevel,
      platoAlimentoId: state.plateLevel > 0 ? state.plateFoodId : null,
      clearPlatoAlimentoId: state.plateLevel <= 0,
      platoEmoji: state.plateLevel > 0 ? state.plateEmoji : null,
      clearPlatoEmoji: state.plateLevel <= 0,
      platoComiendo: eating,
    );
  }

  bool isFoodUnlocked(String id) => _isFoodUnlocked(id);

  String stockLabel(String foodId) {
    final units = state.inventoryUnits[foodId] ?? 0.0;
    final bags = (units / FoodCatalog.bagUnits).toStringAsFixed(1);
    return '$bags bolsas';
  }

  bool _isFoodUnlocked(String id) => state.unlockedFoods[id] ?? false;

  bool _canUseFood(String id) =>
      _isFoodUnlocked(id) && (state.inventoryUnits[id] ?? 0.0) > 0.0;

  List<String> _foodPieces(double plateLevel, String plateEmoji) {
    final pieces = (plateLevel / 20).ceil().clamp(0, 5).toInt();
    return List<String>.generate(pieces, (_) => plateEmoji);
  }

  @override
  Future<void> close() async {
    _pouringTimer?.cancel();
    return super.close();
  }
}
