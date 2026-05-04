import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/mascota_model.dart';

class PetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PetRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _petsRef(String userId) {
    return _firestore.collection('usuarios').doc(userId).collection('mascotas');
  }

  DocumentReference<Map<String, dynamic>> _petRef(String userId, String petId) {
    return _petsRef(userId).doc(petId);
  }

  Future<MascotaModel?> loadActivePet(String userId) async {
    if (userId.isEmpty) return null;

    final snap = await _petsRef(
      userId,
    ).where('activa', isEqualTo: true).limit(1).get();

    if (snap.docs.isEmpty) return null;
    return MascotaModel.fromFirestore(snap.docs.first);
  }

  Future<void> savePet(String userId, MascotaModel mascota) {
    if (userId.isEmpty || mascota.idMascota.isEmpty) {
      return Future.value();
    }

    return _petRef(
      userId,
      mascota.idMascota,
    ).set(mascota.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updatePetFields(
    String userId,
    String petId,
    Map<String, dynamic> fields,
  ) {
    if (userId.isEmpty || petId.isEmpty || fields.isEmpty) {
      return Future.value();
    }

    return _petRef(userId, petId).update(fields);
  }

  Stream<MascotaModel?> watchActivePet(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _petsRef(
      userId,
    ).where('activa', isEqualTo: true).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return MascotaModel.fromFirestore(snap.docs.first);
    });
  }

  Future<void> createPet(String userId, MascotaModel mascota) {
    if (userId.isEmpty || mascota.idMascota.isEmpty) {
      return Future.value();
    }

    return _petRef(userId, mascota.idMascota).set(mascota.toFirestore());
  }
}
