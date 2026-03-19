import 'package:cloud_firestore/cloud_firestore.dart';

// Colección: /usuarios/{id}/mascotas/{id}/progreso/{id_registro}
// Propósito: Registra cada acción del niño. El ML lo lee
//            para aprender las rutinas.

class ProgresoModel {
  final String idRegistro;
  final String idMision;          // Referencia a la misión completada
  final String accionRealizada;   // "alimentar","bañar","jugar","pasear","veterinario"
  final double horaDia;           // Hora en decimal. Ej: 14.5 = 2:30pm
  final DateTime fechaActualizacion;

  // Guardan snapshot de los 5 niveles antes y después de la acción
  // El ML compara ambos para medir el impacto de cada acción
  final Map<String, int> estadoAntes;    // Ej: {salud:80, hambre:30, ...}
  final Map<String, int> estadoDespues;  // Ej: {salud:80, hambre:80, ...}

  const ProgresoModel({
    required this.idRegistro,
    required this.idMision,
    required this.accionRealizada,
    required this.horaDia,
    required this.fechaActualizacion,
    required this.estadoAntes,
    required this.estadoDespues,
  });

  factory ProgresoModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ProgresoModel(
      idRegistro: snapshot.id,
      idMision: data['id_mision'] ?? '',
      accionRealizada: data['accion_realizada'] ?? '',
      horaDia: (data['hora_dia'] ?? 0.0).toDouble(),
      fechaActualizacion: (data['fecha_actualizacion'] as Timestamp).toDate(),
      estadoAntes: Map<String, int>.from(data['estado_antes'] ?? {}),
      estadoDespues: Map<String, int>.from(data['estado_despues'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_mision': idMision,
      'accion_realizada': accionRealizada,
      'hora_dia': horaDia,
      'fecha_actualizacion': Timestamp.fromDate(fechaActualizacion),
      'estado_antes': estadoAntes,
      'estado_despues': estadoDespues,
    };
  }

  // Crea el registro automáticamente al momento de la acción.
  // Calcula hora_dia a partir de la hora actual.
  // Ejemplo de uso:
  //   final registro = ProgresoModel.crear(
  //     idMision: 'mision_alimentar',
  //     accion: 'alimentar',
  //     antes: mascota.nivelesMap,
  //     despues: mascotaActualizada.nivelesMap,
  //   );
  factory ProgresoModel.crear({
    required String idMision,
    required String accion,
    required Map<String, int> antes,
    required Map<String, int> despues,
  }) {
    final ahora = DateTime.now();
    final horaDia = ahora.hour + (ahora.minute / 60.0);
    return ProgresoModel(
      idRegistro: '',
      idMision: idMision,
      accionRealizada: accion,
      horaDia: horaDia,
      fechaActualizacion: ahora,
      estadoAntes: antes,
      estadoDespues: despues,
    );
  }
}
