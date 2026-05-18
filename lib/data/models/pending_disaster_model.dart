import '../../domain/entities/pending_disaster.dart';
import '../../domain/enums/disaster_kind.dart';
import '../../domain/enums/pet_location.dart';

class PendingDisasterModel {
  static PendingDisaster fromFirestore(String id, Map<String, dynamic> data) {
    final kind = _kindFromString((data['tipo'] as String?) ?? '');

    return PendingDisaster(
      id: id,
      kind: kind,
      location: _locationFromData(kind, data['pantalla'] as String?),
      emoji: _resolveEmoji(kind, data['emoji'] as String?),
      quantity: (data['cantidad'] as int?) ?? 1,
      initialQuantity:
          (data['cantidad_inicial'] as int?) ??
          (data['cantidad'] as int?) ??
          1,
      missionId: data['mision_id'] as String?,
      origin: data['origen_residuo'] as String?,
    );
  }

  static DisasterKind _kindFromString(String value) {
    switch (value) {
      case 'comida':
        return DisasterKind.comida;
      case 'juguete':
        return DisasterKind.juguete;
      case 'basura':
        return DisasterKind.basura;
      case 'porcion':
        return DisasterKind.porcion;
      default:
        return DisasterKind.desconocido;
    }
  }

  static PetLocation _locationFromData(DisasterKind kind, String? pantalla) {
    switch (pantalla) {
      case 'home':
        return PetLocation.home;
      case 'alimentar':
        return PetLocation.alimentar;
      case 'jugar':
        return PetLocation.jugar;
      case 'dormir':
        return PetLocation.dormir;
      case 'banar':
        return PetLocation.banar;
      default:
        return _locationFromKind(kind);
    }
  }

  static PetLocation _locationFromKind(DisasterKind kind) {
    switch (kind) {
      case DisasterKind.comida:
        return PetLocation.alimentar;
      case DisasterKind.juguete:
        return PetLocation.jugar;
      case DisasterKind.basura:
        return PetLocation.home;
      case DisasterKind.porcion:
        return PetLocation.alimentar;
      case DisasterKind.desconocido:
        return PetLocation.home;
    }
  }

  static String _resolveEmoji(DisasterKind kind, String? rawEmoji) {
    final cleaned = rawEmoji?.trim() ?? '';
    if (cleaned.isEmpty ||
        cleaned.contains('Ã') ||
        cleaned.contains('ð') ||
        cleaned.contains('â') ||
        cleaned.contains('�')) {
      return switch (kind) {
        DisasterKind.comida => '\u{1F356}',
        DisasterKind.juguete => '\u{1F9F8}',
        DisasterKind.basura => '\u{1F5D1}\u{FE0F}',
        DisasterKind.porcion => '\u{1F963}',
        DisasterKind.desconocido => '\u{2728}',
      };
    }
    return cleaned;
  }
}
