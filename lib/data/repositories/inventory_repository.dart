import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/inventario_comida_model.dart';
import '../../Models/inventario_cosmeticos_model.dart';
import '../../Models/usuario_model.dart';
import '../../core/cosmetic_catalog.dart';
import '../../core/food_catalog.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InventoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('usuarios').doc(userId);
  }

  DocumentReference<Map<String, dynamic>> _foodRef(String userId) {
    return _userRef(userId).collection('inventario').doc('comida');
  }

  DocumentReference<Map<String, dynamic>> _cosmeticsRef(String userId) {
    return _userRef(userId).collection('inventario').doc('cosmeticos');
  }

  Future<void> ensureDefaultInventory(String userId) async {
    await migrateLegacyInventoryIfNeeded(userId);

    final foodSnap = await _foodRef(userId).get();
    if (!foodSnap.exists) {
      await saveFoodInventory(userId, _starterFoodInventory());
    }

    final cosmeticsSnap = await _cosmeticsRef(userId).get();
    if (!cosmeticsSnap.exists) {
      await saveCosmeticsInventory(userId, _starterCosmeticsInventory());
    }
  }

  Future<InventarioComidaModel> loadFoodInventory(String userId) async {
    await migrateLegacyInventoryIfNeeded(userId);
    final snap = await _foodRef(userId).get();
    final model = snap.exists
        ? InventarioComidaModel.fromFirestore(snap)
        : _starterFoodInventory();
    final normalized = _normalizeFood(model);
    await saveFoodInventory(userId, normalized);
    return normalized;
  }

  Future<InventarioCosmeticosModel> loadCosmeticsInventory(
    String userId,
  ) async {
    await migrateLegacyInventoryIfNeeded(userId);
    final snap = await _cosmeticsRef(userId).get();
    final model = snap.exists
        ? InventarioCosmeticosModel.fromFirestore(snap)
        : _starterCosmeticsInventory();
    final normalized = _normalizeCosmetics(model);
    await saveCosmeticsInventory(userId, normalized);
    return normalized;
  }

  Future<void> saveFoodInventory(String userId, InventarioComidaModel model) {
    return _foodRef(userId).set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveCosmeticsInventory(
    String userId,
    InventarioCosmeticosModel model,
  ) {
    return _cosmeticsRef(
      userId,
    ).set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveFoodInventoryAndCoins({
    required String userId,
    required InventarioComidaModel inventory,
    required int coins,
  }) async {
    final batch = _firestore.batch();
    batch.set(_userRef(userId), {
      'monedas': coins,
      'updated_at': FieldValue.serverTimestamp(),
      'totalScore': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.set(
      _foodRef(userId),
      inventory.toFirestore(),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> saveCosmeticsInventoryAndCoins({
    required String userId,
    required InventarioCosmeticosModel inventory,
    required int coins,
  }) async {
    final batch = _firestore.batch();
    batch.set(_userRef(userId), {
      'monedas': coins,
      'updated_at': FieldValue.serverTimestamp(),
      'totalScore': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.set(
      _cosmeticsRef(userId),
      inventory.toFirestore(),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> setCosmeticEquippedOn({
    required String userId,
    required String itemId,
    required String? mascotaId,
    String? previousItemId,
  }) async {
    await ensureDefaultInventory(userId);
    final updates = <String, dynamic>{
      'equipado_en.$itemId': mascotaId,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (previousItemId != null &&
        previousItemId.isNotEmpty &&
        previousItemId != itemId) {
      updates['equipado_en.$previousItemId'] = null;
    }
    await _cosmeticsRef(userId).update(updates);
  }

  Future<void> migrateLegacyInventoryIfNeeded(String userId) async {
    final userRef = _userRef(userId);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final hasLegacyInventory =
        data.containsKey('inventario_comida') ||
        data.containsKey('alimentos_desbloqueados') ||
        data.containsKey('inventario_cosmeticos');
    final hasLegacyUserData =
        data.containsKey('totalScore') ||
        data['tipo_usuario'] == 'niño' ||
        data['tipo_usuario'] == 'niÃ±o';

    if (!hasLegacyInventory && !hasLegacyUserData) return;

    final food = _normalizeFood(
      InventarioComidaModel(
        cantidades: _doubleMap(data['inventario_comida']),
        desbloqueados: _boolMap(data['alimentos_desbloqueados']),
      ),
    );
    final cosmetics = _normalizeCosmetics(
      InventarioCosmeticosModel(
        poseidos: _boolMap(data['inventario_cosmeticos']),
        equipadoEn: const {},
      ),
    );
    final score =
        (data['total_score'] as num?)?.toInt() ??
        (data['totalScore'] as num?)?.toInt() ??
        0;
    final coins =
        (data['monedas'] as num?)?.toInt() ??
        (data['total_score'] as num?)?.toInt() ??
        (data['totalScore'] as num?)?.toInt() ??
        245;

    final batch = _firestore.batch();
    if (hasLegacyInventory) {
      batch.set(_foodRef(userId), food.toFirestore(), SetOptions(merge: true));
      batch.set(
        _cosmeticsRef(userId),
        cosmetics.toFirestore(),
        SetOptions(merge: true),
      );
    }
    batch.update(userRef, {
      'tipo_usuario': UsuarioModel.normalizarTipoUsuario(
        data['tipo_usuario'] as String?,
      ),
      'monedas': coins,
      'total_score': score,
      'updated_at': FieldValue.serverTimestamp(),
      'inventario_comida': FieldValue.delete(),
      'alimentos_desbloqueados': FieldValue.delete(),
      'inventario_cosmeticos': FieldValue.delete(),
      'totalScore': FieldValue.delete(),
    });
    await batch.commit();
  }

  InventarioComidaModel _starterFoodInventory() {
    return InventarioComidaModel(
      cantidades: FoodCatalog.starterInventory(),
      desbloqueados: FoodCatalog.starterUnlocked(),
    );
  }

  InventarioCosmeticosModel _starterCosmeticsInventory() {
    return InventarioCosmeticosModel(
      poseidos: CosmeticCatalog.starterInventory(),
      equipadoEn: const {},
    );
  }

  InventarioComidaModel _normalizeFood(InventarioComidaModel model) {
    final starterInventory = FoodCatalog.starterInventory();
    final starterUnlocked = FoodCatalog.starterUnlocked();
    final cantidades = <String, double>{};
    final desbloqueados = <String, bool>{};

    for (final food in FoodCatalog.items) {
      cantidades[food.id] =
          (model.cantidades[food.id] ?? starterInventory[food.id] ?? 0.0)
              .clamp(0, 99999)
              .toDouble();
      desbloqueados[food.id] =
          model.desbloqueados[food.id] ?? starterUnlocked[food.id] ?? false;
    }

    return InventarioComidaModel(
      cantidades: cantidades,
      desbloqueados: desbloqueados,
    );
  }

  InventarioCosmeticosModel _normalizeCosmetics(
    InventarioCosmeticosModel model,
  ) {
    final starter = CosmeticCatalog.starterInventory();
    final poseidos = <String, bool>{};
    final equipadoEn = <String, String?>{};

    for (final item in CosmeticCatalog.items) {
      poseidos[item.id] = model.poseidos[item.id] ?? starter[item.id] ?? false;
      equipadoEn[item.id] = model.equipadoEn[item.id];
    }

    return InventarioCosmeticosModel(
      poseidos: poseidos,
      equipadoEn: equipadoEn,
    );
  }

  Map<String, double> _doubleMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      return MapEntry(key, value is num ? value.toDouble() : 0.0);
    });
  }

  Map<String, bool> _boolMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      return MapEntry(key, value == true || (value is num && value > 0));
    });
  }
}
