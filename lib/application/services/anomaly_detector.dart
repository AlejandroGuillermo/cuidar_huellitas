import '../../Models/mascota_runtime_model.dart';
import '../../Models/patron_rutina_model.dart';
import '../../data/repositories/patron_rutina_repository.dart';

class AnomalyDetector {
  final PatronRutinaRepository patronRepository;

  const AnomalyDetector({required this.patronRepository});

  Future<bool> detectAnomaly(
    String userId,
    String petId,
    MascotaRuntimeModel runtime,
  ) async {
    final delayed = await getDelayedActions(userId, petId, runtime);
    return delayed.isNotEmpty;
  }

  Future<List<String>> getDelayedActions(
    String userId,
    String petId,
    MascotaRuntimeModel runtime,
  ) async {
    if (userId.isEmpty || petId.isEmpty) return const [];

    final patrones = await patronRepository.getPatrones(userId, petId);
    final patronesActivos = patrones
        .where((patron) => patron.activo && patron.confianza > 0.3)
        .toList();
    if (patronesActivos.isEmpty) return const [];

    final delayedActions = <String>[];
    for (final patron in patronesActivos) {
      if (_isDelayed(patron, runtime)) {
        delayedActions.add(patron.accion);
      }
    }
    return delayedActions;
  }

  bool _isDelayed(PatronRutinaModel patron, MascotaRuntimeModel runtime) {
    final timestamp = _runtimeTimestampForAction(patron.accion, runtime);
    if (timestamp == null && !_supportsAction(patron.accion)) {
      return false;
    }

    final limite = patron.proximaEsperada.add(
      Duration(minutes: patron.ventanaToleranciaMinutos),
    );
    if (!DateTime.now().isAfter(limite)) {
      return false;
    }

    if (timestamp == null) {
      return true;
    }

    return !timestamp.isAfter(patron.ultimaObservacion);
  }

  bool _supportsAction(String accion) {
    return switch (accion) {
      'alimentar' || 'jugar' || 'banar' || 'curar' || 'pasear' => true,
      _ => false,
    };
  }

  DateTime? _runtimeTimestampForAction(
    String accion,
    MascotaRuntimeModel runtime,
  ) {
    switch (accion) {
      case 'alimentar':
        return runtime.ultimaComida;
      case 'jugar':
        return runtime.ultimoJuego;
      case 'banar':
        return runtime.ultimoBano;
      case 'curar':
        return runtime.ultimaCuracion;
      case 'pasear':
        return runtime.ultimoPaseo;
      default:
        return null;
    }
  }
}
