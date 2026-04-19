import '../../Models/mascota_model.dart';
import '../../data/models/pet_world_model.dart';
import '../../data/repositories/world_repository.dart';
import '../../domain/entities/pet_world_state.dart';
import 'pet_activity_resolver.dart';
import 'pet_location_resolver.dart';

class PetBootstrapService {
  final WorldRepository _worldRepository;
  final PetLocationResolver _locationResolver;
  final PetActivityResolver _activityResolver;

  PetBootstrapService({
    required WorldRepository worldRepository,
    required PetLocationResolver locationResolver,
    required PetActivityResolver activityResolver,
  }) : _worldRepository = worldRepository,
       _locationResolver = locationResolver,
       _activityResolver = activityResolver;

  Future<PetWorldState> bootstrap(MascotaModel mascota) async {
    final location = _locationResolver.resolve(mascota);
    final resolvedActivity = _activityResolver.resolve(mascota, location);
    final state = PetWorldState(
      location: location,
      activity: resolvedActivity.activity,
      currentFoodId: resolvedActivity.currentFoodId,
      currentToyId: resolvedActivity.currentToyId,
      simulatedAt: DateTime.now(),
    );

    await _worldRepository.save(mascota.idMascota, PetWorldModel.fromState(state));
    return state;
  }

  Future<void> persist(String mascotaId, PetWorldState state) {
    return _worldRepository.save(mascotaId, PetWorldModel.fromState(state));
  }
}
