import '../enums/mission_kind.dart';
import '../enums/pet_location.dart';

class PendingMission {
  final String id;
  final MissionKind kind;
  final PetLocation location;
  final String status;
  final String? relatedItemId;
  final int rewardCoins;

  const PendingMission({
    required this.id,
    required this.kind,
    required this.location,
    required this.status,
    this.relatedItemId,
    this.rewardCoins = 0,
  });

  bool get isPending => status == 'pendiente';
}
