import 'package:cloud_firestore/cloud_firestore.dart';

// Colección: /usuarios/{id}/mascotas/{id}/misiones_activas/{id}
// Propósito: Copia personal de cada niño. Guarda el estado
//            de su misión y su racha de días consecutivos.

class MisionActivaModel {
  final String idMision;          // Ref a MisionModel (Doc ID de misiones)
  final String estado;            // "pendiente", "completada", "fallida"
  final DateTime fechaAsignada;
  final DateTime? fechaCompletada;
  final int streak;               // Días consecutivos completando esta misión

  const MisionActivaModel({
    required this.idMision,
    required this.estado,
    required this.fechaAsignada,
    this.fechaCompletada,
    this.streak = 0,
  });

  factory MisionActivaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MisionActivaModel(
      idMision: snapshot.id,
      estado: data['estado'] ?? 'pendiente',
      fechaAsignada: (data['fecha_asignada'] as Timestamp).toDate(),
      fechaCompletada: data['fecha_completada'] != null
          ? (data['fecha_completada'] as Timestamp).toDate()
          : null,
      streak: data['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'estado': estado,
      'fecha_asignada': Timestamp.fromDate(fechaAsignada),
      'fecha_completada': fechaCompletada != null
          ? Timestamp.fromDate(fechaCompletada!)
          : null,
      'streak': streak,
    };
  }

  MisionActivaModel copyWith({
    String? estado,
    DateTime? fechaCompletada,
    int? streak,
  }) {
    return MisionActivaModel(
      idMision: idMision,
      estado: estado ?? this.estado,
      fechaAsignada: fechaAsignada,
      fechaCompletada: fechaCompletada ?? this.fechaCompletada,
      streak: streak ?? this.streak,
    );
  }
}
