import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/pending_mission.dart';
import '../models/pending_mission_model.dart';

class MissionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MissionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<List<PendingMission>> loadPending(String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return const [];

    final snap = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('misiones_activas')
        .where('estado', isEqualTo: 'pendiente')
        .get();

    return snap.docs
        .map((doc) => PendingMissionModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
