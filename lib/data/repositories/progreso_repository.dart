import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/progreso_model.dart';

class ProgresoRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProgresoRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _progresoRef(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(petId)
        .collection('progreso');
  }

  Future<void> saveProgreso(
    String userId,
    String petId,
    ProgresoModel progreso,
  ) async {
    if (userId.isEmpty || petId.isEmpty) return;

    final data = progreso.toFirestore();
    if (progreso.idRegistro.isEmpty) {
      await _progresoRef(userId, petId).add(data);
      return;
    }

    await _progresoRef(userId, petId).doc(progreso.idRegistro).set(data);
  }

  Future<List<ProgresoModel>> getRecentProgreso(
    String userId,
    String petId, {
    int limit = 30,
  }) async {
    if (userId.isEmpty || petId.isEmpty || limit <= 0) return const [];

    final snap = await _progresoRef(
      userId,
      petId,
    ).orderBy('fecha_actualizacion', descending: true).limit(limit).get();

    return snap.docs.map(ProgresoModel.fromFirestore).toList();
  }

  Future<List<ProgresoModel>> getProgresoByAccion(
    String userId,
    String petId,
    String accion, {
    int limit = 20,
  }) async {
    if (userId.isEmpty || petId.isEmpty || accion.isEmpty || limit <= 0) {
      return const [];
    }

    final snap = await _progresoRef(userId, petId)
        .where('accion_realizada', isEqualTo: accion)
        .orderBy('fecha_actualizacion', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map(ProgresoModel.fromFirestore).toList();
  }

  Future<List<ProgresoModel>> getProgresoLastDays(
    String userId,
    String petId,
    int days,
  ) async {
    if (userId.isEmpty || petId.isEmpty || days <= 0) return const [];

    final limite = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );

    final snap = await _progresoRef(userId, petId)
        .where('fecha_actualizacion', isGreaterThanOrEqualTo: limite)
        .orderBy('fecha_actualizacion', descending: true)
        .get();

    return snap.docs.map(ProgresoModel.fromFirestore).toList();
  }
}

// Indices Firestore requeridos para estas queries:
// 1. getRecentProgreso:
//    No requiere indice compuesto; basta el indice automatico de
//    fecha_actualizacion para el orderBy descendente.
// 2. getProgresoLastDays:
//    No requiere indice compuesto; el filtro y el orderBy usan el mismo campo
//    fecha_actualizacion.
// 3. getProgresoByAccion:
//    Requiere indice compuesto en la coleccion progreso con:
//    - accion_realizada: Ascending
//    - fecha_actualizacion: Descending
//    Si administran indices por archivo, la definicion equivalente es:
//    {
//      "collectionGroup": "progreso",
//      "queryScope": "COLLECTION",
//      "fields": [
//        { "fieldPath": "accion_realizada", "order": "ASCENDING" },
//        { "fieldPath": "fecha_actualizacion", "order": "DESCENDING" }
//      ]
//    }
