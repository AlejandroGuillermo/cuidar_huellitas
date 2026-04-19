import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pet_world_state.dart';
import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';

class PetWorldModel {
  final PetLocation location;
  final PetActivity activity;
  final String? currentFoodId;
  final String? currentToyId;
  final DateTime simulatedAt;

  const PetWorldModel({
    required this.location,
    required this.activity,
    required this.simulatedAt,
    this.currentFoodId,
    this.currentToyId,
  });

  factory PetWorldModel.fromFirestore(Map<String, dynamic> data) {
    return PetWorldModel(
      location: PetLocation.values.byName(
        (data['current_location'] as String?) ?? PetLocation.home.name,
      ),
      activity: PetActivity.values.byName(
        (data['current_activity'] as String?) ?? PetActivity.idle.name,
      ),
      currentFoodId: data['current_food_id'] as String?,
      currentToyId: data['current_toy_id'] as String?,
      simulatedAt:
          (data['simulated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PetWorldModel.fromState(PetWorldState state) {
    return PetWorldModel(
      location: state.location,
      activity: state.activity,
      currentFoodId: state.currentFoodId,
      currentToyId: state.currentToyId,
      simulatedAt: state.simulatedAt ?? DateTime.now(),
    );
  }

  PetWorldState toState() {
    return PetWorldState(
      location: location,
      activity: activity,
      currentFoodId: currentFoodId,
      currentToyId: currentToyId,
      simulatedAt: simulatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'current_location': location.name,
      'current_activity': activity.name,
      'current_food_id': currentFoodId,
      'current_toy_id': currentToyId,
      'simulated_at': Timestamp.fromDate(simulatedAt),
    };
  }
}
