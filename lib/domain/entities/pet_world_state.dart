import '../enums/pet_activity.dart';
import '../enums/pet_location.dart';

class PetWorldState {
  final bool isLoading;
  final PetLocation location;
  final PetActivity activity;
  final String? currentFoodId;
  final String? currentToyId;
  final bool isLocationLocked;
  final bool isNapTime;
  final DateTime? simulatedAt;

  const PetWorldState({
    this.isLoading = false,
    this.location = PetLocation.home,
    this.activity = PetActivity.idle,
    this.currentFoodId,
    this.currentToyId,
    this.isLocationLocked = false,
    this.isNapTime = false,
    this.simulatedAt,
  });

  PetWorldState copyWith({
    bool? isLoading,
    PetLocation? location,
    PetActivity? activity,
    String? currentFoodId,
    bool clearFood = false,
    String? currentToyId,
    bool clearToy = false,
    bool? isLocationLocked,
    bool? isNapTime,
    DateTime? simulatedAt,
  }) {
    return PetWorldState(
      isLoading: isLoading ?? this.isLoading,
      location: location ?? this.location,
      activity: activity ?? this.activity,
      currentFoodId: clearFood ? null : (currentFoodId ?? this.currentFoodId),
      currentToyId: clearToy ? null : (currentToyId ?? this.currentToyId),
      isLocationLocked: isLocationLocked ?? this.isLocationLocked,
      isNapTime: isNapTime ?? this.isNapTime,
      simulatedAt: simulatedAt ?? this.simulatedAt,
    );
  }

}
