import '../../core/enums/personalidad_tipo.dart';

class PersonalityRules {
  final int homeWeight;
  final int alimentarWeight;
  final int jugarWeight;
  final int dormirWeight;
  final double eatingProbability;
  final double playingProbability;

  const PersonalityRules({
    required this.homeWeight,
    required this.alimentarWeight,
    required this.jugarWeight,
    required this.dormirWeight,
    required this.eatingProbability,
    required this.playingProbability,
  });
}

class PersonalityRulesRegistry {
  static const PersonalityRules _fallback = PersonalityRules(
    homeWeight: 35,
    alimentarWeight: 25,
    jugarWeight: 25,
    dormirWeight: 15,
    eatingProbability: 0.5,
    playingProbability: 0.4,
  );

  static const Map<PersonalidadTipo, PersonalityRules> _rules = {
    PersonalidadTipo.gloton: PersonalityRules(
      homeWeight: 20,
      alimentarWeight: 50,
      jugarWeight: 20,
      dormirWeight: 10,
      eatingProbability: 0.8,
      playingProbability: 0.25,
    ),
    PersonalidadTipo.jugueton: PersonalityRules(
      homeWeight: 20,
      alimentarWeight: 15,
      jugarWeight: 50,
      dormirWeight: 15,
      eatingProbability: 0.45,
      playingProbability: 0.8,
    ),
    PersonalidadTipo.travieso: PersonalityRules(
      homeWeight: 30,
      alimentarWeight: 15,
      jugarWeight: 40,
      dormirWeight: 15,
      eatingProbability: 0.45,
      playingProbability: 0.7,
    ),
    PersonalidadTipo.carinoso: PersonalityRules(
      homeWeight: 40,
      alimentarWeight: 20,
      jugarWeight: 25,
      dormirWeight: 15,
      eatingProbability: 0.5,
      playingProbability: 0.45,
    ),
    PersonalidadTipo.delicado: PersonalityRules(
      homeWeight: 35,
      alimentarWeight: 25,
      jugarWeight: 15,
      dormirWeight: 25,
      eatingProbability: 0.55,
      playingProbability: 0.25,
    ),
  };

  static PersonalityRules getFor(String rasgo) =>
      _rules[PersonalidadTipo.fromString(rasgo)] ?? _fallback;
}
