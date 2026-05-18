import '../../domain/entities/pending_mission.dart';
import '../../domain/enums/mission_kind.dart';
import '../../domain/enums/pet_location.dart';

class PendingMissionModel {
  static const int _defaultRewardCoins = 5;

  static PendingMission fromFirestore(String id, Map<String, dynamic> data) {
    final rawType =
        (data['tipo'] as String?) ?? (data['id_mision'] as String?) ?? '';
    final kind = _kindFromString(rawType);
    final rewardCoins = (data['reward_coins'] as num?)?.toInt() ?? 0;
    final urgency = (data['urgencia'] as num?)?.toInt();

    return PendingMission(
      id: id,
      kind: kind,
      location: _locationFromData(
        kind,
        (data['pantalla_principal'] as String?) ?? (data['pantalla'] as String?),
      ),
      status: (data['estado'] as String?) ?? 'pendiente',
      relatedItemId: data['emoji'] as String?,
      rewardCoins: rewardCoins > 0 ? rewardCoins : _defaultRewardCoins,
      backendTitle: data['titulo'] as String?,
      backendDescription: data['descripcion'] as String?,
      urgency: urgency,
      rawType: rawType,
      bathUrgency: data['urgencia_bano'] as String?,
      targetCount: (data['cantidad_objetivo'] as num?)?.toInt(),
      rewardClaimed: (data['reward_claimed'] as bool?) ?? false,
      primaryScreen:
          (data['pantalla_principal'] as String?) ?? (data['pantalla'] as String?),
      origin: data['origen_residuo'] as String?,
    );
  }

  static MissionKind _kindFromString(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('comida')) return MissionKind.recogerComida;
    if (normalized.contains('juguete')) return MissionKind.recogerJuguete;
    if (normalized.contains('basura') || normalized.contains('residuo')) {
      return MissionKind.recogerBasura;
    }
    return MissionKind.desconocida;
  }

  static PetLocation _locationFromData(MissionKind kind, String? screen) {
    switch (screen) {
      case 'alimentar':
        return PetLocation.alimentar;
      case 'jugar':
        return PetLocation.jugar;
      case 'dormir':
        return PetLocation.dormir;
      case 'curar':
        return PetLocation.curar;
      case 'banar':
        return PetLocation.banar;
      case 'home':
        return PetLocation.home;
    }
    return _locationFromKind(kind);
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
