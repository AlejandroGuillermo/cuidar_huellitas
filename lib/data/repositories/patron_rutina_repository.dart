import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/patron_rutina_model.dart';

class PatronRutinaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PatronRutinaRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _patronesRef(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(petId)
        .collection('patron_rutina');
  }

  String _resolvePatronId(PatronRutinaModel patron) {
    final patronId = patron.idPatron.isNotEmpty
        ? patron.idPatron
        : patron.accion;
    if (patronId.isEmpty) {
      throw ArgumentError(
        'PatronRutinaModel requiere idPatron o accion para persistirse.',
      );
    }
    return patronId;
  }

  Future<List<PatronRutinaModel>> getPatrones(
    String userId,
    String petId,
  ) async {
    if (userId.isEmpty || petId.isEmpty) return const [];

    final snap = await _patronesRef(userId, petId).orderBy('accion').get();
    return snap.docs.map(PatronRutinaModel.fromFirestore).toList();
  }

  Future<PatronRutinaModel?> getPatronByAccion(
    String userId,
    String petId,
    String accion,
  ) async {
    if (userId.isEmpty || petId.isEmpty || accion.isEmpty) return null;

    final snap = await _patronesRef(
      userId,
      petId,
    ).where('accion', isEqualTo: accion).limit(1).get();

    if (snap.docs.isEmpty) return null;
    return PatronRutinaModel.fromFirestore(snap.docs.first);
  }

  Future<void> savePatron(
    String userId,
    String petId,
    PatronRutinaModel patron,
  ) {
    if (userId.isEmpty || petId.isEmpty) return Future.value();

    final patronId = _resolvePatronId(patron);
    return _patronesRef(
      userId,
      petId,
    ).doc(patronId).set(patron.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updatePatron(
    String userId,
    String petId,
    PatronRutinaModel patron,
  ) {
    if (userId.isEmpty || petId.isEmpty) return Future.value();

    final patronId = _resolvePatronId(patron);
    return _patronesRef(
      userId,
      petId,
    ).doc(patronId).update(patron.toFirestore());
  }

  Future<void> deletePatron(String userId, String petId, String idPatron) {
    if (userId.isEmpty || petId.isEmpty || idPatron.isEmpty) {
      return Future.value();
    }

    return _patronesRef(userId, petId).doc(idPatron).delete();
  }
}
