import 'dart:math';

import '../../Models/mascota_model.dart';
import '../../data/models/pet_world_model.dart';
import '../../data/repositories/world_repository.dart';
import '../../domain/entities/pet_world_state.dart';
import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';
import 'pet_activity_resolver.dart';
import 'pet_location_resolver.dart';

class PetBootstrapService {
  final WorldRepository _worldRepository;
  final PetLocationResolver _locationResolver;
  final PetActivityResolver _activityResolver;
  final Random _random;

  static const List<PetLocation> _returnLocations = [
    PetLocation.alimentar,
    PetLocation.home,
    PetLocation.dormir,
    PetLocation.jugar,
  ];

  static const List<String> _toyIds = ['1', '2', '3', '4', '5', '6'];

  PetBootstrapService({
    required WorldRepository worldRepository,
    required PetLocationResolver locationResolver,
    required PetActivityResolver activityResolver,
    Random? random,
  }) : _worldRepository = worldRepository,
       _locationResolver = locationResolver,
       _activityResolver = activityResolver,
       _random = random ?? Random();

  Future<PetWorldState> bootstrap(
    MascotaModel mascota, {
    bool randomizeIfUnlocked = false,
  }) async {
    final persisted = await _worldRepository.load(mascota.idMascota);
    final persistedState = persisted?.toState();

    if (_shouldKeepLockedState(persistedState, mascota)) {
      final locked = _normalizeLockedState(persistedState!, mascota);
      await _worldRepository.save(
        mascota.idMascota,
        PetWorldModel.fromState(locked),
      );
      return locked;
    }

    final state = randomizeIfUnlocked
        ? _buildRandomReturnState(mascota)
        : _buildDeterministicState(mascota);

    await _worldRepository.save(
      mascota.idMascota,
      PetWorldModel.fromState(state),
    );
    return state;
  }

  Future<void> persist(String mascotaId, PetWorldState state) {
    return _worldRepository.save(mascotaId, PetWorldModel.fromState(state));
  }

  bool _shouldKeepLockedState(PetWorldState? state, MascotaModel mascota) {
    if (state == null || !state.isLocationLocked) return false;

    switch (state.location) {
      case PetLocation.alimentar:
        return mascota.nivelPlato > 0;
      case PetLocation.dormir:
        return mascota.estaDescansando ||
            state.activity == PetActivity.sleeping;
      case PetLocation.jugar:
        return state.activity == PetActivity.playing;
      case PetLocation.home:
      case PetLocation.curar:
      case PetLocation.banar:
        return true;
    }
  }

  PetWorldState _normalizeLockedState(
    PetWorldState previous,
    MascotaModel mascota,
  ) {
    switch (previous.location) {
      case PetLocation.alimentar:
        return previous.copyWith(
          location: PetLocation.alimentar,
          activity: PetActivity.eating,
          currentFoodId: mascota.platoAlimentoId.isNotEmpty
              ? mascota.platoAlimentoId
              : previous.currentFoodId,
          clearToy: true,
          isLocationLocked: true,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.dormir:
        return previous.copyWith(
          location: PetLocation.dormir,
          activity: PetActivity.sleeping,
          clearFood: true,
          clearToy: true,
          isLocationLocked: true,
          isNapTime:
              previous.isNapTime ||
              mascota.estadoDescanso == 'siesta' ||
              mascota.tipoDescanso == 'siesta',
          simulatedAt: DateTime.now(),
        );
      case PetLocation.jugar:
        return previous.copyWith(
          location: PetLocation.jugar,
          activity: PetActivity.playing,
          currentToyId: previous.currentToyId ?? _randomToyId(),
          clearFood: true,
          isLocationLocked: true,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.home:
      case PetLocation.curar:
      case PetLocation.banar:
        return previous.copyWith(simulatedAt: DateTime.now());
    }
  }

  PetWorldState _buildDeterministicState(MascotaModel mascota) {
    if (mascota.estaDescansando) {
      return PetWorldState(
        location: PetLocation.dormir,
        activity: PetActivity.sleeping,
        isLocationLocked: true,
        isNapTime:
            mascota.estadoDescanso == 'siesta' ||
            mascota.tipoDescanso == 'siesta',
        simulatedAt: DateTime.now(),
      );
    }

    if (mascota.platoComiendo && mascota.nivelPlato > 0) {
      return PetWorldState(
        location: PetLocation.alimentar,
        activity: PetActivity.eating,
        currentFoodId: mascota.platoAlimentoId.isNotEmpty
            ? mascota.platoAlimentoId
            : null,
        isLocationLocked: true,
        simulatedAt: DateTime.now(),
      );
    }

    final location = _locationResolver.resolve(mascota);
    final resolvedActivity = _activityResolver.resolve(mascota, location);
    return PetWorldState(
      location: location,
      activity: resolvedActivity.activity,
      currentFoodId: resolvedActivity.currentFoodId,
      currentToyId: resolvedActivity.currentToyId,
      isLocationLocked: false,
      isNapTime: false,
      simulatedAt: DateTime.now(),
    );
  }

  PetWorldState _buildRandomReturnState(MascotaModel mascota) {
    final location = _returnLocations[_random.nextInt(_returnLocations.length)];

    switch (location) {
      case PetLocation.alimentar:
        if (mascota.nivelPlato > 0) {
          return PetWorldState(
            location: PetLocation.alimentar,
            activity: PetActivity.eating,
            currentFoodId: mascota.platoAlimentoId.isNotEmpty
                ? mascota.platoAlimentoId
                : null,
            isLocationLocked: true,
            simulatedAt: DateTime.now(),
          );
        }
        return PetWorldState(
          location: PetLocation.alimentar,
          activity: PetActivity.idle,
          isLocationLocked: false,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.dormir:
        return PetWorldState(
          location: PetLocation.dormir,
          activity: PetActivity.sleeping,
          isLocationLocked: true,
          isNapTime: _random.nextDouble() < 0.35,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.jugar:
        return PetWorldState(
          location: PetLocation.jugar,
          activity: PetActivity.playing,
          currentToyId: _randomToyId(),
          isLocationLocked: true,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.home:
        final resolvedActivity = _activityResolver.resolve(
          mascota,
          PetLocation.home,
        );
        return PetWorldState(
          location: PetLocation.home,
          activity: resolvedActivity.activity,
          isLocationLocked: false,
          simulatedAt: DateTime.now(),
        );
      case PetLocation.curar:
      case PetLocation.banar:
        return PetWorldState(
          location: PetLocation.home,
          activity: PetActivity.idle,
          isLocationLocked: false,
          simulatedAt: DateTime.now(),
        );
    }
  }

  String _randomToyId() => _toyIds[_random.nextInt(_toyIds.length)];
}
