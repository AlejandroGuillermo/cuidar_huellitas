import '../enums/mission_kind.dart';
import '../enums/pet_location.dart';

class PendingMission {
  final String id;
  final MissionKind kind;
  final PetLocation location;
  final String status;
  final String? relatedItemId;
  final int rewardCoins;
  final String? backendTitle;
  final String? backendDescription;
  final int? urgency;
  final String? rawType;
  final String? bathUrgency;
  final int? targetCount;
  final bool rewardClaimed;
  final String? primaryScreen;
  final String? origin;

  const PendingMission({
    required this.id,
    required this.kind,
    required this.location,
    required this.status,
    this.relatedItemId,
    this.rewardCoins = 0,
    this.backendTitle,
    this.backendDescription,
    this.urgency,
    this.rawType,
    this.bathUrgency,
    this.targetCount,
    this.rewardClaimed = false,
    this.primaryScreen,
    this.origin,
  });

  bool get isPending => status == 'pendiente';
  bool get isCompleted => status == 'completada';
  bool get canClaimReward => isCompleted && !rewardClaimed;

  bool get isUrgent {
    if (bathUrgency == 'urgente') return true;
    if (urgency != null) return urgency! <= 2;

    return switch (_normalizedId) {
      'gloton_alimentar_critico' => true,
      'gloton_alimentar_urgente' => true,
      'jugueton_jugar_urgente' => true,
      'jugueton_dormir' => true,
      'carinoso_urgente' => true,
      'delicado_curar' => true,
      'mision_bano' => true,
      _ => false,
    };
  }

  String get title {
    if (_trimmed(backendTitle) case final value?) return value;

    return switch (_normalizedId) {
      'cuidar_salud' => 'Curar a tu mascota',
      'alimentar' => 'Dar de comer',
      'descansar' => 'Hora de descansar',
      'limpiar' => 'Aseo necesario',
      'jugar_afecto' => 'Dale atencion',
      'jugar_rutina' => 'Hora de jugar',
      'jugueton_dormir' => 'Esta agotado',
      'jugueton_jugar_urgente' => 'Quiere jugar ya',
      'travieso_calmar' => 'Calma a tu mascota',
      'travieso_limpiar' => 'Limpia el desastre',
      'gloton_alimentar_urgente' => 'Tiene mucha hambre',
      'gloton_alimentar_critico' => 'Hambre critica',
      'carinoso_jugar' => 'Necesita carino',
      'carinoso_urgente' => 'Se siente muy solo',
      'delicado_curar' => 'No se siente bien',
      'mision_bano' => 'Bano necesario',
      'limpiar_residuos' => 'Limpiar residuos',
      _ when kind == MissionKind.recogerComida => 'Recoge la comida tirada',
      _ when kind == MissionKind.recogerJuguete => 'Recoge los juguetes',
      _ when kind == MissionKind.recogerBasura => 'Limpia la basura',
      _ => 'Mision activa',
    };
  }

  String get description {
    if (_trimmed(backendDescription) case final value?) return value;

    return switch (_normalizedId) {
      'cuidar_salud' => 'Su salud necesita atencion inmediata.',
      'alimentar' => 'Necesita comer cuanto antes.',
      'descansar' => 'Necesita descansar un poco.',
      'limpiar' => 'Necesita limpieza para sentirse mejor.',
      'jugar_afecto' => 'Necesita atencion y compania.',
      'jugar_rutina' => 'Necesita una rutina de juego para no aburrirse.',
      'jugueton_dormir' =>
        'Tu mascota juguetona esta muy cansada y necesita dormir.',
      'jugueton_jugar_urgente' =>
        'Tu mascota esta aburrida y quiere jugar contigo.',
      'travieso_calmar' => 'Atiendela antes de que haga mas travesuras.',
      'travieso_limpiar' => 'Su espacio esta sucio y necesita que lo limpies.',
      'gloton_alimentar_urgente' =>
        'Rellena su plato antes de que se quede sin comida.',
      'gloton_alimentar_critico' =>
        'Tu mascota necesita comida de inmediato.',
      'carinoso_jugar' =>
        'Juega con tu mascota para que se sienta querida.',
      'carinoso_urgente' => 'Necesita tiempo contigo cuanto antes.',
      'delicado_curar' =>
        'Llevala a curacion para ayudarla a sentirse mejor.',
      'mision_bano' =>
        'Tu mascota necesita un bano para recuperar su limpieza.',
      'limpiar_residuos' => _residueDescription,
      _ when kind == MissionKind.recogerComida =>
        'Recoge la comida para mantener limpio el espacio de tu mascota.',
      _ when kind == MissionKind.recogerJuguete =>
        'Recoge los juguetes que quedaron fuera de lugar.',
      _ when kind == MissionKind.recogerBasura =>
        'Limpia la basura para que tu mascota este comoda y sana.',
      _ => 'Revisa la mision pendiente y completala desde la pantalla indicada.',
    };
  }

  String get emoji {
    if (_trimmed(relatedItemId) case final value?) return value;

    return switch (_normalizedId) {
      'cuidar_salud' => '\u{1F48A}',
      'alimentar' => '\u{1F37D}\u{FE0F}',
      'descansar' => '\u{1F634}',
      'limpiar' => '\u{1F6C1}',
      'jugar_afecto' => '\u{1F3BE}',
      'jugar_rutina' => '\u{1F9F8}',
      'jugueton_dormir' => '\u{26A1}',
      'jugueton_jugar_urgente' => '\u{1F3BE}',
      'travieso_calmar' => '\u{1F608}',
      'travieso_limpiar' => '\u{1F9F9}',
      'gloton_alimentar_urgente' => '\u{1F356}',
      'gloton_alimentar_critico' => '\u{1F6A8}',
      'carinoso_jugar' => '\u{1F970}',
      'carinoso_urgente' => '\u{1F494}',
      'delicado_curar' => '\u{1F912}',
      'mision_bano' => '\u{1F6C1}',
      'limpiar_residuos' => '\u{1F5D1}\u{FE0F}',
      _ when kind == MissionKind.recogerComida => '\u{1F356}',
      _ when kind == MissionKind.recogerJuguete => '\u{1F3BE}',
      _ when kind == MissionKind.recogerBasura => '\u{1F9F9}',
      _ => '\u{1F6A8}',
    };
  }

  String get actionLabel {
    return switch (resolvedLocation) {
      PetLocation.home => 'Ir al inicio',
      PetLocation.alimentar => 'Ir a alimentar',
      PetLocation.jugar => 'Ir a jugar',
      PetLocation.dormir => 'Ir a dormir',
      PetLocation.curar => 'Ir a curar',
      PetLocation.banar => 'Ir a banar',
    };
  }

  PetLocation get resolvedLocation {
    return switch (_normalizedId) {
      'cuidar_salud' => PetLocation.curar,
      'alimentar' => PetLocation.alimentar,
      'descansar' => PetLocation.dormir,
      'limpiar' => PetLocation.banar,
      'jugar_afecto' => PetLocation.jugar,
      'jugar_rutina' => PetLocation.jugar,
      'jugueton_dormir' => PetLocation.dormir,
      'jugueton_jugar_urgente' => PetLocation.jugar,
      'travieso_calmar' => PetLocation.jugar,
      'travieso_limpiar' => PetLocation.home,
      'gloton_alimentar_urgente' => PetLocation.alimentar,
      'gloton_alimentar_critico' => PetLocation.alimentar,
      'carinoso_jugar' => PetLocation.jugar,
      'carinoso_urgente' => PetLocation.jugar,
      'delicado_curar' => PetLocation.curar,
      'mision_bano' => PetLocation.banar,
      'limpiar_residuos' => _locationFromPrimaryScreen(),
      _ => location,
    };
  }

  String get _normalizedId => id.toLowerCase();

  String get _residueDescription {
    switch (origin) {
      case 'ia_clean':
        return 'Recoge los residuos del area de bano para mantener su espacio impecable.';
      case 'ia_dirty':
        return 'Se generaron residuos en varias areas. Recogelos para recuperar el orden.';
      case 'delicado':
        return 'Tu mascota delicada dejo residuos en varias areas. Recogelos con cuidado.';
      default:
        return 'Recoge los residuos que aparecieron en casa para cuidar el bienestar de tu mascota.';
    }
  }

  PetLocation _locationFromPrimaryScreen() {
    return switch (primaryScreen) {
      'alimentar' => PetLocation.alimentar,
      'jugar' => PetLocation.jugar,
      'dormir' => PetLocation.dormir,
      'curar' => PetLocation.curar,
      'banar' => PetLocation.banar,
      _ => PetLocation.home,
    };
  }

  String? _trimmed(String? value) {
    if (value == null) return null;
    final trimmed = _normalizeLegacyText(value).trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _normalizeLegacyText(String value) {
    return value
        .replaceAll('ÃƒÆ’Ã‚Â±', 'n')
        .replaceAll('ÃƒÂ±', 'n')
        .replaceAll('ÃƒÆ’Ã‚Â¡', 'a')
        .replaceAll('ÃƒÂ¡', 'a')
        .replaceAll('ÃƒÆ’Ã‚Â©', 'e')
        .replaceAll('ÃƒÂ©', 'e')
        .replaceAll('ÃƒÆ’Ã‚Â­', 'i')
        .replaceAll('ÃƒÂ­', 'i')
        .replaceAll('ÃƒÆ’Ã‚Â³', 'o')
        .replaceAll('ÃƒÂ³', 'o')
        .replaceAll('ÃƒÆ’Ã‚Âº', 'u')
        .replaceAll('ÃƒÂº', 'u')
        .replaceAll('Ã‚', '');
  }
}
