import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Models/mascota_model.dart';
import '../../domain/entities/pet_world_state.dart';
import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';
import '../services/pet_bootstrap_service.dart';

class PetWorldCubit extends Cubit<PetWorldState> {
  final PetBootstrapService _bootstrapService;

  PetWorldCubit({required PetBootstrapService bootstrapService})
    : _bootstrapService = bootstrapService,
      super(const PetWorldState(isLoading: true));

  Future<void> bootstrap(
    MascotaModel? mascota, {
    bool randomizeIfUnlocked = false,
  }) async {
    if (mascota == null) {
      emit(const PetWorldState(isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true));
    final resolved = await _bootstrapService.bootstrap(
      mascota,
      randomizeIfUnlocked: randomizeIfUnlocked,
    );
    emit(resolved.copyWith(isLoading: false));
  }

  Future<void> updateWorld({
    required MascotaModel mascota,
    PetWorldState? next,
  }) async {
    final updated = next ?? state.copyWith(simulatedAt: DateTime.now());
    emit(updated);
    await _bootstrapService.persist(
      mascota.idMascota,
      updated.copyWith(isLoading: false),
    );
  }

  Future<void> syncScreenEntry({
    required MascotaModel mascota,
    required PetLocation location,
    PetActivity fallbackActivity = PetActivity.idle,
  }) async {
    if (state.isLoading) return;
    if (state.isLocationLocked && state.location != location) return;

    final next = state.copyWith(
      location: location,
      activity: state.isLocationLocked ? state.activity : fallbackActivity,
      simulatedAt: DateTime.now(),
    );
    await updateWorld(mascota: mascota, next: next);
  }
}
