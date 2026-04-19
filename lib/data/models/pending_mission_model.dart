import '../../domain/entities/pending_mission.dart';
import '../../domain/enums/mission_kind.dart';
import '../../domain/enums/pet_location.dart';

class PendingMissionModel {
  static PendingMission fromFirestore(String id, Map<String, dynamic> data) {
    final rawType =
        (data['tipo'] as String?) ?? (data['id_mision'] as String?) ?? '';

    return PendingMission(
      id: id,
      kind: _kindFromString(rawType),
      location: _locationFromKind(_kindFromString(rawType)),
      status: (data['estado'] as String?) ?? 'pendiente',
      relatedItemId: data['emoji'] as String?,
    );
  }

  static MissionKind _kindFromString(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('comida')) return MissionKind.recogerComida;
    if (normalized.contains('juguete')) return MissionKind.recogerJuguete;
    if (normalized.contains('basura')) return MissionKind.recogerBasura;
    return MissionKind.desconocida;
  }

  static PetLocation _locationFromKind(MissionKind kind) {
    switch (kind) {
      case MissionKind.recogerComida:
        return PetLocation.alimentar;
      case MissionKind.recogerJuguete:
        return PetLocation.jugar;
      case MissionKind.recogerBasura:
        return PetLocation.home;
      case MissionKind.desconocida:
        return PetLocation.home;
    }
  }
}
