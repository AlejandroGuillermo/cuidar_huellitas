import 'package:cloud_firestore/cloud_firestore.dart';

// Colección: /patrones_rutina  (colección raíz, nueva)
// Propósito: Aquí vive lo que el Motor de IA aprende.
//            Un documento por acción por usuario.
//            Ej: usuario "abc123" → acción "alimentar" → aprende 7:40am

class PatronRutinaModel {
  final String idPatron;
  final String idUsuario;         // A qué niño pertenece
  final String accion;            // "alimentar","bañar","jugar","pasear","veterinario"
  final double horaPromedio;      // Hora promedio en decimal. Ej: 7.66 = 7:40am
  final double desviacionStd;     // Qué tan puntual es el niño.
                                  // Pequeño = muy puntual → umbral estricto
                                  // Grande = irregular → umbral tolerante
  final double frecuenciaDia;     // Veces por día que hace esta acción
  final double confianza;         // 0.0 a 1.0. Sube con más datos.
                                  // Con < 7 registros es baja (0.3)
                                  // Con 30+ registros sube a 0.9+
  final DateTime ultimaCalc;      // Cuándo se recalculó el patrón

  const PatronRutinaModel({
    required this.idPatron,
    required this.idUsuario,
    required this.accion,
    required this.horaPromedio,
    required this.desviacionStd,
    required this.frecuenciaDia,
    required this.confianza,
    required this.ultimaCalc,
  });

  factory PatronRutinaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return PatronRutinaModel(
      idPatron: snapshot.id,
      idUsuario: data['id_usuario'] ?? '',
      accion: data['accion'] ?? '',
      horaPromedio: (data['hora_promedio'] ?? 12.0).toDouble(),
      desviacionStd: (data['desviacion_std'] ?? 2.0).toDouble(),
      frecuenciaDia: (data['frecuencia_dia'] ?? 1.0).toDouble(),
      confianza: (data['confianza'] ?? 0.3).toDouble(),
      ultimaCalc: (data['ultima_calc'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_usuario': idUsuario,
      'accion': accion,
      'hora_promedio': horaPromedio,
      'desviacion_std': desviacionStd,
      'frecuencia_dia': frecuenciaDia,
      'confianza': confianza,
      'ultima_calc': Timestamp.fromDate(ultimaCalc),
    };
  }

  // Detecta si la hora actual es una anomalía.
  // Retorna true si el retraso supera 2 veces la desviación estándar.
  // Ejemplo: horaPromedio=7.66, desviacionStd=0.28
  //   hora 10.0 → retraso 2.34 > 2×0.28=0.56 → true (anomalía)
  //   hora 7.9  → retraso 0.24 > 0.56         → false (normal)
  bool esAnomalia(double horaActual) {
    final retraso = (horaActual - horaPromedio).abs();
    return retraso > (2 * desviacionStd);
  }
}
