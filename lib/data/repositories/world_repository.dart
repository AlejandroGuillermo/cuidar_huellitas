import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_world_model.dart';

class WorldRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorldRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<PetWorldModel?> load(String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return null;

    final doc = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('world_state')
        .doc('current')
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return PetWorldModel.fromFirestore(doc.data()!);
  }

  Future<void> save(String mascotaId, PetWorldModel model) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || mascotaId.isEmpty) return;

    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('world_state')
        .doc('current')
        .set(model.toFirestore(), SetOptions(merge: true));
  }
}
