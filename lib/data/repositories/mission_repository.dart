import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/mision_activa_model.dart';
import '../../domain/entities/pending_mission.dart';
import '../models/pending_mission_model.dart';

class MissionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MissionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _missionsRef(
    String userId,
    String mascotaId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('misiones_activas');
  }

  Future<List<PendingMission>> loadPending(String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return const [];

    final snap = await _missionsRef(
      userId,
      mascotaId,
    ).where('estado', isEqualTo: 'pendiente').get();

    return snap.docs
        .map((doc) => PendingMissionModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<MisionActivaModel>> loadActiveMissionModels(
    String mascotaId,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return const [];

    final snap = await _missionsRef(
      userId,
      mascotaId,
    ).where('estado', isEqualTo: 'pendiente').get();

    return snap.docs.map(MisionActivaModel.fromFirestore).toList();
  }

  Future<void> cancelActiveMissions(
    String mascotaId,
    Iterable<String> missionIds,
  ) async {
    final userId = _auth.currentUser?.uid;
    final ids = missionIds.where((id) => id.isNotEmpty).toSet().toList();
    if (userId == null || mascotaId.isEmpty || ids.isEmpty) return;

    final batch = _firestore.batch();
    final ahora = Timestamp.now();
    for (final missionId in ids) {
      batch.set(_missionsRef(userId, mascotaId).doc(missionId), {
        'estado': 'fallida',
        'fecha_completada': ahora,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<PendingMission>> watchPending(String mascotaId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) {
      return Stream.value(const []);
    }

    return _missionsRef(userId, mascotaId)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => PendingMissionModel.fromFirestore(doc.id, doc.data()),
              )
              .toList(),
        );
  }
}
