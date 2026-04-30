import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pet_world_state.dart';
import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';

class PetWorldModel {
  final PetLocation location;
  final PetActivity activity;
  final String? currentFoodId;
  final String? currentToyId;
  final bool isLocationLocked;
  final bool isNapTime;
  final DateTime simulatedAt;

  const PetWorldModel({
    required this.location,
    required this.activity,
    required this.simulatedAt,
    this.currentFoodId,
    this.currentToyId,
    this.isLocationLocked = false,
    this.isNapTime = false,
  });

  factory PetWorldModel.fromFirestore(Map<String, dynamic> data) {
    final rawLocation = data['current_location'] as String?;
    final rawActivity = data['current_activity'] as String?;

    final parsedLocation = PetLocation.values.where(
      (e) => e.name == rawLocation,
    );
    final parsedActivity = PetActivity.values.where(
      (e) => e.name == rawActivity,
    );

    return PetWorldModel(
      location: parsedLocation.isNotEmpty
          ? parsedLocation.first
          : PetLocation.home,
      activity: parsedActivity.isNotEmpty
          ? parsedActivity.first
          : PetActivity.idle,
      currentFoodId: data['current_food_id'] as String?,
      currentToyId: data['current_toy_id'] as String?,
      isLocationLocked: (data['location_locked'] as bool?) ?? false,
      isNapTime: (data['sleeping_nap'] as bool?) ?? false,
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
      isLocationLocked: state.isLocationLocked,
      isNapTime: state.isNapTime,
      simulatedAt: state.simulatedAt ?? DateTime.now(),
    );
  }

  PetWorldState toState() {
    return PetWorldState(
      location: location,
      activity: activity,
      currentFoodId: currentFoodId,
      currentToyId: currentToyId,
      isLocationLocked: isLocationLocked,
      isNapTime: isNapTime,
      simulatedAt: simulatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'current_location': location.name,
      'current_activity': activity.name,
      'current_food_id': currentFoodId,
      'current_toy_id': currentToyId,
      'location_locked': isLocationLocked,
      'sleeping_nap': isNapTime,
      'simulated_at': Timestamp.fromDate(simulatedAt),
    };
  }
}
