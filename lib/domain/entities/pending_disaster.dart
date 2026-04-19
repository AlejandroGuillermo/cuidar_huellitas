import '../enums/disaster_kind.dart';
import '../enums/pet_location.dart';

class PendingDisaster {
  final String id;
  final DisasterKind kind;
  final PetLocation location;
  final String emoji;
  final int quantity;

  const PendingDisaster({
    required this.id,
    required this.kind,
    required this.location,
    required this.emoji,
    required this.quantity,
  });
}
