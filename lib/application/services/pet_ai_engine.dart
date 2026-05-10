import '../../Models/mascota_model.dart';
import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';
import '../models/pet_ai_decision.dart';
import 'anomaly_detector.dart';
import 'fuzzy_state_engine.dart';
import 'pet_emotion_resolver.dart';
import 'pet_needs_evaluator.dart';

class PetAiEngine {
  final PetNeedsEvaluator needsEvaluator;
  final FuzzyStateEngine fuzzyEngine;
  final PetEmotionResolver emotionResolver;
  final AnomalyDetector? anomalyDetector;

  PetAiEngine({
    required this.needsEvaluator,
    required this.fuzzyEngine,
    required this.emotionResolver,
    this.anomalyDetector,
  });

  PetAiDecision evaluate(MascotaModel mascota) {
    return _evaluateResolved(mascota, delayedActions: const []);
  }

  Future<PetAiDecision> evaluateAsync(
    MascotaModel mascota,
    String userId,
  ) async {
    if (userId.isEmpty || anomalyDetector == null) {
      return evaluate(mascota);
    }

    final anomaliaActiva = await anomalyDetector!.detectAnomaly(
      userId,
      mascota.idMascota,
      mascota.runtime,
    );
    final delayedActions = await anomalyDetector!.getDelayedActions(
      userId,
      mascota.idMascota,
      mascota.runtime,
    );

    final mascotaActualizada = mascota.copyWith(
      anomaliaActiva: anomaliaActiva,
      anomaliaDetectada: anomaliaActiva,
    );

    return _evaluateResolved(
      mascotaActualizada,
      delayedActions: delayedActions,
    );
  }

  PetAiDecision _evaluateResolved(
    MascotaModel mascota, {
    required List<String> delayedActions,
  }) {
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
      anomaliaActiva: mascota.ai.anomaliaActiva,
      misionRecomendada: _recommendMission(needResult.need, emotion),
      mensaje: _buildMessage(needResult.need, emotion, delayedActions),
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

  String _buildMessage(
    PetNeed need,
    PetEmotion emotion,
    List<String> delayedActions,
  ) {
    final baseMessage = need != PetNeed.none
        ? 'Necesita ${need.toDisplayString().toLowerCase()}'
        : switch (emotion) {
            PetEmotion.happy => 'Tu mascota se siente feliz',
            PetEmotion.sad => 'Tu mascota necesita compania',
            PetEmotion.sick => 'Tu mascota no se siente bien',
            PetEmotion.dirty => 'Tu mascota necesita limpieza',
            PetEmotion.tired => 'Tu mascota necesita descansar',
            PetEmotion.hungry => 'Tu mascota quiere comer',
            PetEmotion.bored => 'Tu mascota esta aburrida',
            PetEmotion.neutral => 'Tu mascota esta estable',
          };

    if (delayedActions.isEmpty) {
      return baseMessage;
    }

    final delayedLabel = delayedActions.map(_displayAction).join(', ');
    return '$baseMessage. Acciones retrasadas: $delayedLabel.';
  }

  bool _shouldGenerateDisaster(PetNeed need, PetEmotion emotion) {
    return need == PetNeed.hygiene || emotion == PetEmotion.bored;
  }

  String _displayAction(String accion) {
    return switch (accion) {
      'alimentar' => 'alimentar',
      'jugar' => 'jugar',
      'banar' => 'banar',
      'curar' => 'curar',
      'pasear' => 'pasear',
      _ => accion,
    };
  }
}
