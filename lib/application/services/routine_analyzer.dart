import 'dart:math';

import '../../Models/patron_rutina_model.dart';
import '../../Models/progreso_model.dart';
import '../../data/repositories/patron_rutina_repository.dart';
import '../../data/repositories/progreso_repository.dart';

class RoutineAnalyzer {
  final ProgresoRepository progresoRepository;
  final PatronRutinaRepository patronRepository;

  const RoutineAnalyzer({
    required this.progresoRepository,
    required this.patronRepository,
  });

  Future<void> analyzeAndUpdate(String userId, String petId) async {
    if (userId.isEmpty || petId.isEmpty) return;

    final progreso = await progresoRepository.getRecentProgreso(
      userId,
      petId,
      limit: 30,
    );
    if (progreso.isEmpty) return;

    final grouped = <String, List<ProgresoModel>>{};
    for (final registro in progreso) {
      final accion = _normalizeAction(registro.accionRealizada);
      if (accion == null) continue;
      grouped.putIfAbsent(accion, () => <ProgresoModel>[]).add(registro);
    }

    for (final entry in grouped.entries) {
      final accion = entry.key;
      final registros = entry.value;
      if (registros.length < 3) continue;

      registros.sort(
        (a, b) => a.fechaActualizacion.compareTo(b.fechaActualizacion),
      );

      final horas = registros.map((item) => item.horaDia).toList();
      final horaPromedio = horas.reduce((a, b) => a + b) / horas.length;
      final desviacionStd = _calculateStdDev(horas, horaPromedio);
      final totalMuestras = registros.length;
      final primerRegistro = registros.first.fechaActualizacion;
      final ultimoRegistro = registros.last.fechaActualizacion;
      final rangoDias = max(
        1.0,
        ultimoRegistro.difference(primerRegistro).inMinutes /
            Duration.minutesPerDay,
      );
      final frecuenciaDia = totalMuestras / rangoDias;
      final confianza = min(totalMuestras / 10.0, 1.0);
      final ultimaObservacion = ultimoRegistro;
      final minutosHastaProxima = ((24 / frecuenciaDia) * 60).round();
      final proximaEsperada = ultimaObservacion.add(
        Duration(minutes: minutosHastaProxima),
      );
      final ventanaToleranciaMinutos = (desviacionStd * 60).round().clamp(
        15,
        120,
      );

      final existente = await patronRepository.getPatronByAccion(
        userId,
        petId,
        accion,
      );

      final patron = PatronRutinaModel(
        idPatron: existente?.idPatron ?? accion,
        idUsuario: userId,
        idMascota: petId,
        accion: accion,
        horaPromedio: horaPromedio,
        desviacionStd: desviacionStd,
        frecuenciaDia: frecuenciaDia,
        confianza: confianza,
        ultimaCalc: DateTime.now(),
        totalMuestras: totalMuestras,
        ultimaObservacion: ultimaObservacion,
        proximaEsperada: proximaEsperada,
        ventanaToleranciaMinutos: ventanaToleranciaMinutos,
        activo: true,
      );

      if (existente != null) {
        await patronRepository.updatePatron(userId, petId, patron);
      } else {
        await patronRepository.savePatron(userId, petId, patron);
      }
    }
  }

  Future<List<PatronRutinaModel>> getPatrones(String userId, String petId) {
    return patronRepository.getPatrones(userId, petId);
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;

    final variance =
        values
            .map((value) => pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  String? _normalizeAction(String accion) {
    final normalized = accion.trim().toLowerCase();
    switch (normalized) {
      case 'alimentar':
        return 'alimentar';
      case 'jugar':
        return 'jugar';
      case 'banar':
      case 'bañar':
        return 'banar';
      case 'curar':
      case 'veterinario':
        return 'curar';
      case 'pasear':
        return 'pasear';
      default:
        return null;
    }
  }
}
