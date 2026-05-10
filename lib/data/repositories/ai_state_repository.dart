import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiHistoryEntry {
  final String id;
  final DateTime createdAt;
  final double deterioroRate;
  final bool anomaliaActiva;
  final String estadoEmocional;
  final String necesidadPrioritaria;
  final String? mensaje;
  final String source;

  const AiHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.deterioroRate,
    required this.anomaliaActiva,
    required this.estadoEmocional,
    required this.necesidadPrioritaria,
    required this.mensaje,
    required this.source,
  });

  factory AiHistoryEntry.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AiHistoryEntry(
      id: snapshot.id,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      deterioroRate: (data['deterioro_rate'] as num?)?.toDouble() ?? 1.0,
      anomaliaActiva: data['anomalia_activa'] ?? false,
      estadoEmocional: data['estado_emocional'] ?? 'neutral',
      necesidadPrioritaria: data['necesidad_prioritaria'] ?? 'Sin necesidad',
      mensaje: data['mensaje'],
      source: data['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      'deterioro_rate': deterioroRate,
      'anomalia_activa': anomaliaActiva,
      'estado_emocional': estadoEmocional,
      'necesidad_prioritaria': necesidadPrioritaria,
      'mensaje': mensaje,
      'source': source,
    };
  }
}

class AiStateRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AiStateRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _historyRef(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(petId)
        .collection('ai_history');
  }

  Future<void> saveEntry(
    String userId,
    String petId,
    AiHistoryEntry entry,
  ) async {
    if (userId.isEmpty || petId.isEmpty) return;

    if (entry.id.isEmpty) {
      await _historyRef(userId, petId).add(entry.toFirestore());
      return;
    }

    await _historyRef(userId, petId).doc(entry.id).set(entry.toFirestore());
  }

  Future<List<AiHistoryEntry>> getHistory(
    String userId,
    String petId, {
    int limit = 20,
  }) async {
    if (userId.isEmpty || petId.isEmpty || limit <= 0) return const [];

    final snap = await _historyRef(
      userId,
      petId,
    ).orderBy('created_at', descending: true).limit(limit).get();

    return snap.docs.map(AiHistoryEntry.fromFirestore).toList();
  }

  Future<void> deleteOldEntries(
    String userId,
    String petId, {
    int keepLast = 50,
  }) async {
    if (userId.isEmpty || petId.isEmpty || keepLast <= 0) return;

    final snap = await _historyRef(
      userId,
      petId,
    ).orderBy('created_at', descending: true).get();

    if (snap.docs.length <= keepLast) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs.skip(keepLast)) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
