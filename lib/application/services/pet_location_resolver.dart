import 'dart:math';

import '../../domain/enums/pet_location.dart';
import '../../domain/rules/personality_rules.dart';
import '../../Models/mascota_model.dart';

class PetLocationResolver {
  final Random _random;

  PetLocationResolver({Random? random}) : _random = random ?? Random();

  PetLocation resolve(MascotaModel mascota) {
    if (mascota.estadoDescanso == 'dormido' || mascota.estadoDescanso == 'siesta') {
      return PetLocation.dormir;
    }

    final rules = PersonalityRulesRegistry.getFor(mascota.rasgo);
    final total =
        rules.homeWeight +
        rules.alimentarWeight +
        rules.jugarWeight +
        rules.dormirWeight;
    final roll = _random.nextInt(total);

    if (roll < rules.homeWeight) return PetLocation.home;
    if (roll < rules.homeWeight + rules.alimentarWeight) {
      return PetLocation.alimentar;
    }
    if (roll < rules.homeWeight + rules.alimentarWeight + rules.jugarWeight) {
      return PetLocation.jugar;
    }
    return PetLocation.dormir;
  }
}
