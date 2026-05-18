import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/mision_activa_model.dart';
import '../../domain/entities/pending_mission.dart';
import 'user_repository.dart';
import '../models/pending_mission_model.dart';

class MissionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  MissionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _userRepository = UserRepository(
        firestore: firestore,
        auth: auth,
      );

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

  Future<List<PendingMission>> loadCompletedToday(String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return const [];

    final startOfDay = DateTime.now();
    final today = DateTime(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
    );

    final snap = await _missionsRef(userId, mascotaId)
        .where(
          'fecha_completada',
          isGreaterThanOrEqualTo: Timestamp.fromDate(today),
        )
        .orderBy('fecha_completada', descending: true)
        .get();

    return snap.docs
        .map((doc) => PendingMissionModel.fromFirestore(doc.id, doc.data()))
        .where((mission) => mission.status == 'completada')
        .toList();
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
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => PendingMissionModel.fromFirestore(doc.id, doc.data()),
              )
              .where(
                (mission) =>
                    mission.status == 'pendiente' ||
                    (mission.status == 'completada' && !mission.rewardClaimed),
              )
              .toList(),
        );
  }

  Future<int> claimReward(String mascotaId, String missionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty || missionId.isEmpty) return 0;

    final missionRef = _missionsRef(userId, mascotaId).doc(missionId);
    var claimedCoins = 0;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(missionRef);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final status = (data['estado'] as String?) ?? 'pendiente';
      final rewardClaimed = (data['reward_claimed'] as bool?) ?? false;
      if (status != 'completada' || rewardClaimed) return;

      claimedCoins = (data['reward_coins'] as num?)?.toInt() ?? 5;
      tx.set(missionRef, {
        'reward_claimed': true,
        'fecha_cobro': Timestamp.now(),
      }, SetOptions(merge: true));
    });

    if (claimedCoins > 0) {
      await _userRepository.addCoins(userId, claimedCoins);
    }
    return claimedCoins;
  }

  Future<void> completeMission(String mascotaId, String missionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty || missionId.isEmpty) return;

    final missionRef = _missionsRef(userId, mascotaId).doc(missionId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(missionRef);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final status = (data['estado'] as String?) ?? 'pendiente';
      if (status != 'pendiente') return;

      tx.set(missionRef, {
        'estado': 'completada',
        'fecha_completada': Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }
}
