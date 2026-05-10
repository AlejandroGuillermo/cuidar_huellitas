import '../../Models/mascota_model.dart';
import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';
import '../models/pet_ai_decision.dart';
import 'fuzzy_state_engine.dart';
import 'pet_emotion_resolver.dart';
import 'pet_needs_evaluator.dart';

class PetAiEngine {
  final PetNeedsEvaluator needsEvaluator;
  final FuzzyStateEngine fuzzyEngine;
  final PetEmotionResolver emotionResolver;

  const PetAiEngine({
    required this.needsEvaluator,
    required this.fuzzyEngine,
    required this.emotionResolver,
  });

  PetAiDecision evaluate(MascotaModel mascota) {
    final needResult = needsEvaluator.evaluate(mascota.stats);
    final deterioroRate = fuzzyEngine.evaluate(
      mascota.stats,
      mascota.personalidad,
      anomaliaActiva: mascota.ai.anomaliaActiva,
    );
    final emotion = emotionResolver.resolve(
      mascota.stats,
      mascota.runtime,
      mascota.personalidad,
    );

    return PetAiDecision(
      needPriority: needResult.need,
      needScore: needResult.score,
      emotion: emotion,
      deterioroRate: deterioroRate,
      misionRecomendada: _recommendMission(needResult.need, emotion),
      mensaje: _buildMessage(needResult.need, emotion),
      generarDesastre: _shouldGenerateDisaster(needResult.need, emotion),
      calculadoAt: DateTime.now(),
    );
  }

  String? _recommendMission(PetNeed need, PetEmotion emotion) {
    switch (need) {
      case PetNeed.health:
        return 'cuidar_salud';
      case PetNeed.hunger:
        return 'alimentar_urgente';
      case PetNeed.energy:
        return 'descansar_urgente';
      case PetNeed.hygiene:
        return 'limpiar_urgente';
      case PetNeed.affection:
        return 'jugar_urgente';
      case PetNeed.none:
        if (emotion == PetEmotion.bored) {
          return 'jugar_urgente';
        }
        return null;
    }
  }

  String _buildMessage(PetNeed need, PetEmotion emotion) {
    if (need != PetNeed.none) {
      return 'Necesita ${need.toDisplayString().toLowerCase()}';
    }

    return switch (emotion) {
      PetEmotion.happy => 'Tu mascota se siente feliz',
      PetEmotion.sad => 'Tu mascota necesita compania',
      PetEmotion.sick => 'Tu mascota no se siente bien',
      PetEmotion.dirty => 'Tu mascota necesita limpieza',
      PetEmotion.tired => 'Tu mascota necesita descansar',
      PetEmotion.hungry => 'Tu mascota quiere comer',
      PetEmotion.bored => 'Tu mascota esta aburrida',
      PetEmotion.neutral => 'Tu mascota esta estable',
    };
  }

  bool _shouldGenerateDisaster(PetNeed need, PetEmotion emotion) {
    return need == PetNeed.hygiene || emotion == PetEmotion.bored;
  }
}
