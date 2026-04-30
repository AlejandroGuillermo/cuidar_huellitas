import 'dart:math';

import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';
import '../../domain/rules/personality_rules.dart';
import '../../Models/mascota_model.dart';

class ResolvedPetActivity {
  final PetActivity activity;
  final String? currentFoodId;
  final String? currentToyId;

  const ResolvedPetActivity({
    required this.activity,
    this.currentFoodId,
    this.currentToyId,
  });
}

class PetActivityResolver {
  final Random _random;

  static const List<String> _foodIds = [
    'carne',
    'hueso',
    'zanahoria',
    'pescado',
    'pollo',
    'leche',
  ];

  static const List<String> _toyIds = ['1', '2', '3', '4', '5', '6'];

  PetActivityResolver({Random? random}) : _random = random ?? Random();

  ResolvedPetActivity resolve(MascotaModel mascota, PetLocation location) {
    if (mascota.estadoDescanso == 'dormido' ||
        mascota.estadoDescanso == 'siesta' ||
        mascota.estadoDescanso == 'acostado') {
      return const ResolvedPetActivity(activity: PetActivity.sleeping);
    }

    if (location == PetLocation.alimentar &&
        mascota.platoComiendo &&
        mascota.nivelPlato > 0) {
      return ResolvedPetActivity(
        activity: PetActivity.eating,
        currentFoodId: mascota.platoAlimentoId.isNotEmpty
            ? mascota.platoAlimentoId
            : _foodIds[_random.nextInt(_foodIds.length)],
      );
    }

    final rules = PersonalityRulesRegistry.getFor(mascota.rasgo);

    switch (location) {
      case PetLocation.alimentar:
        final eating = _random.nextDouble() < rules.eatingProbability;
        return ResolvedPetActivity(
          activity: eating ? PetActivity.eating : PetActivity.idle,
          currentFoodId: eating
              ? _foodIds[_random.nextInt(_foodIds.length)]
              : null,
        );
      case PetLocation.jugar:
        final playing = _random.nextDouble() < rules.playingProbability;
        return ResolvedPetActivity(
          activity: playing ? PetActivity.playing : PetActivity.idle,
          currentToyId: playing
              ? _toyIds[_random.nextInt(_toyIds.length)]
              : null,
        );
      case PetLocation.dormir:
        return const ResolvedPetActivity(activity: PetActivity.idle);
      case PetLocation.home:
        return ResolvedPetActivity(
          activity: _random.nextBool() ? PetActivity.roaming : PetActivity.idle,
        );
      case PetLocation.curar:
      case PetLocation.banar:
        return const ResolvedPetActivity(activity: PetActivity.idle);
    }
  }
}
