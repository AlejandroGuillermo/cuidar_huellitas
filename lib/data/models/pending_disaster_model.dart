import '../../domain/entities/pending_disaster.dart';
import '../../domain/enums/disaster_kind.dart';
import '../../domain/enums/pet_location.dart';

class PendingDisasterModel {
  static PendingDisaster fromFirestore(String id, Map<String, dynamic> data) {
    final kind = _kindFromString((data['tipo'] as String?) ?? '');

    return PendingDisaster(
      id: id,
      kind: kind,
      location: _locationFromKind(kind),
      emoji: (data['emoji'] as String?) ?? '🧹',
      quantity: (data['cantidad'] as int?) ?? 1,
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
}
