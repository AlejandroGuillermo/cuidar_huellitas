import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/usuario_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> refFor(String userId) {
    return _firestore.collection('usuarios').doc(userId);
  }

  Future<UsuarioModel?> loadCurrent() async {
    final userId = currentUserId;
    if (userId == null) return null;
    final snap = await refFor(userId).get();
    if (!snap.exists) return null;
    return UsuarioModel.fromFirestore(snap);
  }

  Future<void> save(UsuarioModel user) {
    return refFor(
      user.idUsuario,
    ).set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<int> loadCoins(String userId, {int fallback = 245}) async {
    final snap = await refFor(userId).get();
    final data = snap.data() ?? <String, dynamic>{};
    return _coinsFromData(data, fallback: fallback);
  }

  Future<void> setCoins(String userId, int coins) {
    return refFor(userId).set({
      'monedas': coins,
      'updated_at': FieldValue.serverTimestamp(),
      'totalScore': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<int> addCoins(String userId, int coins) async {
    if (coins <= 0) return loadCoins(userId, fallback: 0);

    final userRef = refFor(userId);
    var total = 0;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final actuales = _coinsFromData(data, fallback: 0);
      total = actuales + coins;
      tx.set(userRef, {
        'monedas': total,
        'updated_at': FieldValue.serverTimestamp(),
        'totalScore': FieldValue.delete(),
      }, SetOptions(merge: true));
    });
    return total;
  }

  Future<void> normalizeLegacyUserDoc(String userId) async {
    final userRef = refFor(userId);
    final snap = await userRef.get();
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};
    final type = UsuarioModel.normalizarTipoUsuario(
      data['tipo_usuario'] as String?,
    );
    final score =
        (data['total_score'] as num?)?.toInt() ??
        (data['totalScore'] as num?)?.toInt() ??
        0;
    final coins = _coinsFromData(data);

    await userRef.set({
      'tipo_usuario': type,
      'monedas': coins,
      'total_score': score,
      'totalScore': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _coinsFromData(Map<String, dynamic> data, {int fallback = 245}) {
    return (data['monedas'] as num?)?.toInt() ??
        (data['total_score'] as num?)?.toInt() ??
        (data['totalScore'] as num?)?.toInt() ??
        fallback;
  }
}
