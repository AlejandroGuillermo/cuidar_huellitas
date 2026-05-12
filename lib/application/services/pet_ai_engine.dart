import '../../Models/mascota_model.dart';
import '../../Models/mision_activa_model.dart';
import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';
import '../models/pet_ai_decision.dart';
import 'anomaly_detector.dart';
import 'fuzzy_state_engine.dart';
import 'mission_decision_engine.dart';
import 'pet_emotion_resolver.dart';
import 'pet_needs_evaluator.dart';

class PetAiEngine {
  final PetNeedsEvaluator needsEvaluator;
  final FuzzyStateEngine fuzzyEngine;
  final PetEmotionResolver emotionResolver;
  final AnomalyDetector? anomalyDetector;
  final MissionDecisionEngine? missionEngine;

  PetAiEngine({
    required this.needsEvaluator,
    required this.fuzzyEngine,
    required this.emotionResolver,
    this.anomalyDetector,
    this.missionEngine,
  });

  PetAiDecision evaluate(MascotaModel mascota) {
    return _evaluateResolved(mascota, delayedActions: const []);
  }

  Future<PetAiDecision> evaluateAsync(
    MascotaModel mascota,
    String userId, {
    List<MisionActivaModel> misionesActivas = const [],
  }) async {
    var mascotaActualizada = mascota;
    var delayedActions = const <String>[];

    if (userId.isNotEmpty && anomalyDetector != null) {
      final anomaliaActiva = await anomalyDetector!.detectAnomaly(
        userId,
        mascota.idMascota,
        mascota.runtime,
      );
      delayedActions = await anomalyDetector!.getDelayedActions(
        userId,
        mascota.idMascota,
        mascota.runtime,
      );

      mascotaActualizada = mascota.copyWith(
        anomaliaActiva: anomaliaActiva,
        anomaliaDetectada: anomaliaActiva,
      );
    }

    final baseDecision = _evaluateResolved(
      mascotaActualizada,
      delayedActions: delayedActions,
    );
    return _applyMissionAndDisasterLogic(
      mascotaActualizada,
      baseDecision,
      misionesActivas: misionesActivas,
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
      misionRecomendada: null,
      urgenciaMision: null,
      reemplazarActiva: false,
      misionesAReemplazar: const [],
      mensaje: _buildFallbackMessage(needResult.need, emotion, delayedActions),
      generarDesastre: false,
      calculadoAt: DateTime.now(),
    );
  }

  Future<PetAiDecision> _applyMissionAndDisasterLogic(
    MascotaModel mascota,
    PetAiDecision baseDecision, {
    required List<MisionActivaModel> misionesActivas,
    required List<String> delayedActions,
  }) async {
    var decision = baseDecision.copyWith(
      generarDesastre: _shouldConsiderDisaster(baseDecision),
    );

    if (missionEngine != null) {
      final missionDecision = await missionEngine!.decide(
        mascota,
        decision,
        misionesActivas,
      );

      if (missionDecision != null) {
        decision = decision.copyWith(
          misionRecomendada: missionDecision.misionId,
          urgenciaMision: missionDecision.urgencia,
          reemplazarActiva: missionDecision.reemplazarActiva,
          misionesAReemplazar: missionDecision.misionesAReemplazar,
          mensaje: _appendDelayedActions(
            missionDecision.mensaje,
            delayedActions,
          ),
        );
      } else if (delayedActions.isNotEmpty && decision.mensaje != null) {
        decision = decision.copyWith(
          mensaje: _appendDelayedActions(decision.mensaje!, delayedActions),
        );
      }
    } else if (delayedActions.isNotEmpty && decision.mensaje != null) {
      decision = decision.copyWith(
        mensaje: _appendDelayedActions(decision.mensaje!, delayedActions),
      );
    }

    return decision;
  }

  String _buildFallbackMessage(
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

  bool _shouldConsiderDisaster(PetAiDecision decision) {
    return true;
  }

  String _appendDelayedActions(
    String baseMessage,
    List<String> delayedActions,
  ) {
    if (delayedActions.isEmpty) {
      return baseMessage;
    }

    final delayedLabel = delayedActions.map(_displayAction).join(', ');
    if (baseMessage.contains('Acciones retrasadas:')) {
      return baseMessage;
    }
    return '$baseMessage. Acciones retrasadas: $delayedLabel.';
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
