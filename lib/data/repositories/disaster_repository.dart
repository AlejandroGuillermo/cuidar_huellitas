import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/pending_disaster.dart';
import '../models/pending_disaster_model.dart';

class DisasterRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DisasterRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<PendingDisaster>> loadPending(String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return const [];

    final snap = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('desastres_pendientes')
        .where('recogido', isEqualTo: false)
        .get();

    return snap.docs
        .map((doc) => PendingDisasterModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Stream<List<PendingDisaster>> watchPending(String mascotaId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('desastres_pendientes')
        .where('recogido', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => PendingDisasterModel.fromFirestore(doc.id, doc.data()),
              )
              .toList(),
        );
  }
}
