import 'package:cloud_firestore/cloud_firestore.dart';

// Coleccion: /usuarios/{id}/mascotas/{id}/patron_rutina/{idPatron}
// Proposito: Persistir los patrones calculados por accion para una mascota.
class PatronRutinaModel {
  final String idPatron;
  final String idUsuario;
  final String idMascota;
  final String accion;
  final double horaPromedio;
  final double desviacionStd;
  final double frecuenciaDia;
  final double confianza;
  final DateTime ultimaCalc;
  final int totalMuestras;
  final DateTime ultimaObservacion;
  final DateTime proximaEsperada;
  final int ventanaToleranciaMinutos;
  final bool activo;

  const PatronRutinaModel({
    required this.idPatron,
    required this.idUsuario,
    required this.idMascota,
    required this.accion,
    required this.horaPromedio,
    required this.desviacionStd,
    required this.frecuenciaDia,
    required this.confianza,
    required this.ultimaCalc,
    required this.totalMuestras,
    required this.ultimaObservacion,
    required this.proximaEsperada,
    required this.ventanaToleranciaMinutos,
    required this.activo,
  });

  factory PatronRutinaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    DateTime? timestampToDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final ultimaCalc = timestampToDate(data['ultima_calc']) ?? DateTime.now();
    final ultimaObservacion =
        timestampToDate(data['ultima_observacion']) ?? ultimaCalc;
    final proximaEsperada =
        timestampToDate(data['proxima_esperada']) ?? ultimaObservacion;

    return PatronRutinaModel(
      idPatron: snapshot.id,
      idUsuario: data['id_usuario'] ?? '',
      idMascota: data['id_mascota'] ?? '',
      accion: data['accion'] ?? '',
      horaPromedio: (data['hora_promedio'] ?? 0.0).toDouble(),
      desviacionStd: (data['desviacion_std'] ?? 0.0).toDouble(),
      frecuenciaDia: (data['frecuencia_dia'] ?? 0.0).toDouble(),
      confianza: (data['confianza'] ?? 0.0).toDouble(),
      ultimaCalc: ultimaCalc,
      totalMuestras: (data['total_muestras'] as num?)?.toInt() ?? 0,
      ultimaObservacion: ultimaObservacion,
      proximaEsperada: proximaEsperada,
      ventanaToleranciaMinutos:
          (data['ventana_tolerancia_minutos'] as num?)?.toInt() ?? 0,
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_usuario': idUsuario,
      'id_mascota': idMascota,
      'accion': accion,
      'hora_promedio': horaPromedio,
      'desviacion_std': desviacionStd,
      'frecuencia_dia': frecuenciaDia,
      'confianza': confianza,
      'ultima_calc': Timestamp.fromDate(ultimaCalc),
      'total_muestras': totalMuestras,
      'ultima_observacion': Timestamp.fromDate(ultimaObservacion),
      'proxima_esperada': Timestamp.fromDate(proximaEsperada),
      'ventana_tolerancia_minutos': ventanaToleranciaMinutos,
      'activo': activo,
    };
  }

  PatronRutinaModel copyWith({
    String? idPatron,
    String? idUsuario,
    String? idMascota,
    String? accion,
    double? horaPromedio,
    double? desviacionStd,
    double? frecuenciaDia,
    double? confianza,
    DateTime? ultimaCalc,
    int? totalMuestras,
    DateTime? ultimaObservacion,
    DateTime? proximaEsperada,
    int? ventanaToleranciaMinutos,
    bool? activo,
  }) {
    return PatronRutinaModel(
      idPatron: idPatron ?? this.idPatron,
      idUsuario: idUsuario ?? this.idUsuario,
      idMascota: idMascota ?? this.idMascota,
      accion: accion ?? this.accion,
      horaPromedio: horaPromedio ?? this.horaPromedio,
      desviacionStd: desviacionStd ?? this.desviacionStd,
      frecuenciaDia: frecuenciaDia ?? this.frecuenciaDia,
      confianza: confianza ?? this.confianza,
      ultimaCalc: ultimaCalc ?? this.ultimaCalc,
      totalMuestras: totalMuestras ?? this.totalMuestras,
      ultimaObservacion: ultimaObservacion ?? this.ultimaObservacion,
      proximaEsperada: proximaEsperada ?? this.proximaEsperada,
      ventanaToleranciaMinutos:
          ventanaToleranciaMinutos ?? this.ventanaToleranciaMinutos,
      activo: activo ?? this.activo,
    );
  }

  bool esAnomalia(double horaActual) {
    final retraso = (horaActual - horaPromedio).abs();
    return retraso > (2 * desviacionStd);
  }
}
