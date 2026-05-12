import '../../Models/mascota_model.dart';
import '../../Models/mision_activa_model.dart';
import '../../core/enums/personalidad_tipo.dart';
import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';
import '../../data/repositories/mission_repository.dart';
import '../models/pet_ai_decision.dart';

class MisionDecision {
  final String misionId;
  final String petId;
  final int urgencia;
  final String mensaje;
  final bool reemplazarActiva;
  final List<String> misionesAReemplazar;

  const MisionDecision({
    required this.misionId,
    required this.petId,
    required this.urgencia,
    required this.mensaje,
    required this.reemplazarActiva,
    required this.misionesAReemplazar,
  });
}

class MissionDecisionEngine {
  final MissionRepository missionRepository;

  const MissionDecisionEngine({required this.missionRepository});

  Future<MisionDecision?> decide(
    MascotaModel mascota,
    PetAiDecision aiDecision,
    List<MisionActivaModel> misionesActivas,
  ) async {
    final resolvedMisiones = misionesActivas.isNotEmpty
        ? misionesActivas
        : await missionRepository.loadActiveMissionModels(mascota.idMascota);

    final missionId = _resolveMissionId(aiDecision);
    if (missionId == null) return null;

    var urgencia = _resolveUrgency(aiDecision);
    if (urgencia == null) return null;
    if (aiDecision.anomaliaActiva) {
      urgencia = (urgencia - 1).clamp(1, 4);
    }

    final nuevaCategoria = _missionCategoryFromId(missionId);
    final misionesMismaCategoria = <String>[];
    final misionesMenorUrgencia = <String>[];

    for (final activa in resolvedMisiones.where(
      (item) => item.estado == 'pendiente',
    )) {
      final urgenciaActiva = _urgencyFromMissionId(activa.idMision);
      if (urgenciaActiva < urgencia) {
        return null;
      }

      final categoriaActiva = _missionCategoryFromId(activa.idMision);
      if (categoriaActiva == nuevaCategoria) {
        misionesMismaCategoria.add(activa.idMision);
      } else if (urgenciaActiva >= urgencia) {
        misionesMenorUrgencia.add(activa.idMision);
      }
    }

    final misionesAReemplazar = <String>{
      ...misionesMismaCategoria,
      ...misionesMenorUrgencia,
    }.toList();

    return MisionDecision(
      misionId: missionId,
      petId: mascota.idMascota,
      urgencia: urgencia,
      mensaje: _buildMessage(mascota.personalidad, aiDecision.needPriority),
      reemplazarActiva: misionesAReemplazar.isNotEmpty,
      misionesAReemplazar: misionesAReemplazar,
    );
  }

  String? _resolveMissionId(PetAiDecision decision) {
    if (decision.needPriority == PetNeed.none) {
      return decision.emotion == PetEmotion.bored ? 'jugar_rutina' : null;
    }

    return switch (decision.needPriority) {
      PetNeed.health => 'cuidar_salud',
      PetNeed.hunger => 'alimentar',
      PetNeed.energy => 'descansar',
      PetNeed.hygiene => 'limpiar',
      PetNeed.affection => 'jugar_afecto',
      PetNeed.none => null,
    };
  }

  int? _resolveUrgency(PetAiDecision decision) {
    if (decision.needPriority == PetNeed.health && decision.needScore >= 100) {
      return 1;
    }

    return switch (decision.needPriority) {
      PetNeed.hunger => 2,
      PetNeed.energy => 2,
      PetNeed.hygiene => 3,
      PetNeed.affection => 3,
      PetNeed.none => decision.emotion == PetEmotion.bored ? 4 : null,
      PetNeed.health => 1,
    };
  }

  String _buildMessage(PersonalidadTipo personalidad, PetNeed needPriority) {
    if (personalidad == PersonalidadTipo.travieso &&
        needPriority != PetNeed.none) {
      return 'Esta causando problemas. Atiendelo antes de que empeore.';
    }

    switch (personalidad) {
      case PersonalidadTipo.gloton:
        if (needPriority == PetNeed.hunger) {
          return 'Tiene muchisima hambre. Alimentalo pronto.';
        }
        break;
      case PersonalidadTipo.carinoso:
        if (needPriority == PetNeed.affection) {
          return 'Se siente solo y necesita tu atencion.';
        }
        break;
      case PersonalidadTipo.delicado:
        if (needPriority == PetNeed.hygiene) {
          return 'Esta muy incomodo. Necesita un bano urgente.';
        }
        break;
      case PersonalidadTipo.jugueton:
        if (needPriority == PetNeed.energy) {
          return 'Esta agotado de tanto jugar. Necesita descansar.';
        }
        break;
      case PersonalidadTipo.travieso:
        break;
    }

    return switch (needPriority) {
      PetNeed.health => 'Su salud necesita atencion inmediata.',
      PetNeed.hunger => 'Necesita comer cuanto antes.',
      PetNeed.energy => 'Necesita descansar un poco.',
      PetNeed.hygiene => 'Necesita limpieza para sentirse mejor.',
      PetNeed.affection => 'Necesita atencion y compania.',
      PetNeed.none => 'Necesita una rutina de juego para no aburrirse.',
    };
  }

  int _urgencyFromMissionId(String missionId) {
    final category = _missionCategoryFromId(missionId);
    return switch (category) {
      _MissionCategory.health => 1,
      _MissionCategory.hunger => 2,
      _MissionCategory.energy => 2,
      _MissionCategory.hygiene => 3,
      _MissionCategory.affection => 3,
      _MissionCategory.bored => 4,
      _MissionCategory.unknown => 4,
    };
  }

  _MissionCategory _missionCategoryFromId(String missionId) {
    final normalized = missionId.toLowerCase();

    if (normalized.contains('salud') || normalized.contains('curar')) {
      return _MissionCategory.health;
    }
    if (normalized.contains('aliment')) {
      return _MissionCategory.hunger;
    }
    if (normalized.contains('descans') || normalized.contains('dorm')) {
      return _MissionCategory.energy;
    }
    if (normalized.contains('limpiar') ||
        normalized.contains('basura') ||
        normalized.contains('ban')) {
      return _MissionCategory.hygiene;
    }
    if (normalized.contains('jugar_rutina')) {
      return _MissionCategory.bored;
    }
    if (normalized.contains('jugar')) {
      return _MissionCategory.affection;
    }
    return _MissionCategory.unknown;
  }
}

enum _MissionCategory {
  health,
  hunger,
  energy,
  hygiene,
  affection,
  bored,
  unknown,
}
