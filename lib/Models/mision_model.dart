import 'package:cloud_firestore/cloud_firestore.dart';

// Colección: /misiones  (global, no es subcolección)
// Propósito: Plantillas de misiones. Se crean una sola vez
//            y todos los usuarios las comparten.

class MisionModel {
  final String idMision;
  final String titulo;
  final String descripcion;
  final int recompensa;           // Puntos XP al completar
  final String tipoMision;        // "diaria" o "semanal"
  final String tipoAccion;        // "alimentar","bañar","jugar","pasear","veterinario"
  final String condicionDisparo;  // Cuándo se activa esta misión
  final int tiempoLimite;         // Segundos para completarla
  final String educationalTip;    // Dato educativo que aparece al completar

  const MisionModel({
    required this.idMision,
    required this.titulo,
    required this.descripcion,
    required this.recompensa,
    required this.tipoMision,
    required this.tipoAccion,
    required this.condicionDisparo,
    required this.tiempoLimite,
    required this.educationalTip,
  });

  factory MisionModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MisionModel(
      idMision: snapshot.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      recompensa: data['recompensa'] ?? 0,
      tipoMision: data['tipo_mision'] ?? 'diaria',
      tipoAccion: data['tipo_accion'] ?? '',
      condicionDisparo: data['condicion_disparo'] ?? '',
      tiempoLimite: data['tiempoLimite'] ?? 0,
      educationalTip: data['educationalTip'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'recompensa': recompensa,
      'tipo_mision': tipoMision,
      'tipo_accion': tipoAccion,
      'condicion_disparo': condicionDisparo,
      'tiempoLimite': tiempoLimite,
      'educationalTip': educationalTip,
    };
  }
}
